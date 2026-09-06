--!nonstrict
--[[
    CoinSpawner.luau
    Manages zone coin node spawning using CollectionService and surface normal geometry math.
    Detects upward-facing surfaces on builder-placed marker parts, computes 2D boundaries,
    and distributes styled collectible CoinNode parts across platforms.
    Delegates pickup validation, audio, and node respawning to CoinService.luau.
    Location: src/server/Services/CoinSpawner.luau (Syncs to ServerScriptService.Server.Services.CoinSpawner)
--]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TemplateUtil = require(Shared:WaitForChild("Utils"):WaitForChild("TemplateUtil"))

local Services = script.Parent
local CoinService = require(Services:WaitForChild("CoinService"))

local CoinSpawner = {}
local CoinNodesFolder: Folder
local processedSpawners = setmetatable({}, { __mode = "k" }) :: { [BasePart]: boolean }
local coinNodeCounter = 0

--- Computes dot products to identify which face of the part is facing upwards into the sky
local function getUpwardFaceData(part: BasePart)
	local cf = part.CFrame
	local size = part.Size

	local faces = {
		{
			normal = cf.UpVector,
			normalExtent = size.Y / 2,
			tangentU = cf.RightVector,
			extentU = size.X,
			tangentV = cf.LookVector,
			extentV = size.Z,
		},
		{
			normal = -cf.UpVector,
			normalExtent = size.Y / 2,
			tangentU = cf.RightVector,
			extentU = size.X,
			tangentV = cf.LookVector,
			extentV = size.Z,
		},
		{
			normal = cf.RightVector,
			normalExtent = size.X / 2,
			tangentU = cf.UpVector,
			extentU = size.Y,
			tangentV = cf.LookVector,
			extentV = size.Z,
		},
		{
			normal = -cf.RightVector,
			normalExtent = size.X / 2,
			tangentU = cf.UpVector,
			extentU = size.Y,
			tangentV = cf.LookVector,
			extentV = size.Z,
		},
		{
			normal = cf.LookVector,
			normalExtent = size.Z / 2,
			tangentU = cf.RightVector,
			extentU = size.X,
			tangentV = cf.UpVector,
			extentV = size.Y,
		},
		{
			normal = -cf.LookVector,
			normalExtent = size.Z / 2,
			tangentU = cf.RightVector,
			extentU = size.X,
			tangentV = cf.UpVector,
			extentV = size.Y,
		},
	}

	local bestFace = faces[1]
	local maxDot = -math.huge

	for _, face in ipairs(faces) do
		local dot = face.normal:Dot(Vector3.yAxis)
		if dot > maxDot then
			maxDot = dot
			bestFace = face
		end
	end

	return bestFace
end

--- Calculates spawn points by tiling/filling the upward face area with a set distance between coins
local function calculateSurfaceSpawnPoints(
	part: BasePart,
	hoverHeight: number,
	margin: number,
	spacing: number,
	explicitCount: number?
): { Vector3 }
	local face = getUpwardFaceData(part)
	local cf = part.CFrame
	local surfaceCenter = cf.Position + (face.normal * face.normalExtent)
	local baseSpawnCenter = surfaceCenter + (face.normal * hoverHeight)

	local points: { Vector3 } = {}

	local usableU = math.max(0, face.extentU - (margin * 2))
	local usableV = math.max(0, face.extentV - (margin * 2))

	-- If the surface is tiny or usable area is smaller than a minimal threshold, place 1 at the center
	if usableU <= 0.5 and usableV <= 0.5 then
		table.insert(points, baseSpawnCenter)
		return points
	end

	-- If an explicit count was provided as an optional override, respect it
	if explicitCount and explicitCount > 0 then
		if explicitCount == 1 then
			table.insert(points, baseSpawnCenter)
			return points
		end

		local useUAxis = (usableU >= usableV)
		if usableU < 1 or usableV < 1 then
			local axisVector = if useUAxis then face.tangentU else face.tangentV
			local axisLen = if useUAxis then usableU else usableV
			local halfLen = axisLen / 2
			for i = 1, explicitCount do
				local t = (i - 0.5) / explicitCount
				table.insert(points, baseSpawnCenter + (axisVector * (-halfLen + (t * axisLen))))
			end
			return points
		end
	end

	-- Automatic area filling: compute columns along U and rows along V based on spacing
	local cols = 1
	if usableU >= (spacing * 0.75) then
		cols = math.max(1, math.round(usableU / spacing))
	end

	local rows = 1
	if usableV >= (spacing * 0.75) then
		rows = math.max(1, math.round(usableV / spacing))
	end

	-- Safety clamp from Config to prevent excessive parts
	local spawnerCfg = Config.COIN_SPAWNER or {}
	local maxCoins = spawnerCfg.MAX_COINS_PER_SURFACE or 36
	if (cols * rows) > maxCoins then
		local scale = math.sqrt(maxCoins / (cols * rows))
		cols = math.max(1, math.floor(cols * scale))
		rows = math.max(1, math.floor(rows * scale))
	end

	local halfU = usableU / 2
	local halfV = usableV / 2

	for r = 1, rows do
		for c = 1, cols do
			local tU = if cols > 1 then (c - 0.5) / cols else 0.5
			local tV = if rows > 1 then (r - 0.5) / rows else 0.5

			local offsetU = if cols > 1 then (-halfU + (tU * usableU)) else 0
			local offsetV = if rows > 1 then (-halfV + (tV * usableV)) else 0

			local point = baseSpawnCenter + (face.tangentU * offsetU) + (face.tangentV * offsetV)
			table.insert(points, point)
		end
	end

	return points
end

--- Creates an active physical coin node at the specified position
local function createCoinNode(name: string, pos: Vector3, zoneTier: number): BasePart
	local node = TemplateUtil.CloneCoinTemplate()
	node.Name = name
	node.Position = pos
	node.Anchored = true
	node.CanCollide = false
	node.CanTouch = true
	node:SetAttribute("Active", true)
	node:SetAttribute("ZoneTier", zoneTier)

	-- Apply Zone Tier Color if configured
	local spawnerCfg = Config.COIN_SPAWNER
	if spawnerCfg and spawnerCfg.TIER_COLORS and spawnerCfg.TIER_COLORS[zoneTier] then
		node.Color = spawnerCfg.TIER_COLORS[zoneTier]
	end

	-- Tag part for client-side CollectionService streaming and animations
	local nodeTag = (spawnerCfg and spawnerCfg.NODE_TAG) or "CoinNode"
	CollectionService:AddTag(node, nodeTag)

	node.Parent = CoinNodesFolder

	node.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			CoinSpawner.HandlePickup(player, node)
		end
	end)

	return node
end

--- Configures a spawner part: reads attributes, calculates upward surface points, and creates coins
local function processSpawnerPart(spawnerPart: BasePart)
	if not spawnerPart:IsA("BasePart") then return end
	if processedSpawners[spawnerPart] then return end
	processedSpawners[spawnerPart] = true

	local spawnerCfg = Config.COIN_SPAWNER or {}
	local zoneTier = spawnerPart:GetAttribute("ZoneTier") or 1
	local hoverHeight = spawnerPart:GetAttribute("HoverHeight") or spawnerCfg.DEFAULT_HOVER_HEIGHT or 2.0
	local safetyMargin = spawnerPart:GetAttribute("SafetyMargin") or spawnerCfg.SAFETY_MARGIN or 2.5
	local spacing = spawnerPart:GetAttribute("CoinSpacing") or spawnerCfg.COIN_SPACING or 8.0
	local explicitCount = spawnerPart:GetAttribute("CoinCount") -- Optional override

	local spawnPoints = calculateSurfaceSpawnPoints(spawnerPart, hoverHeight, safetyMargin, spacing, explicitCount)

	for i, pos in ipairs(spawnPoints) do
		coinNodeCounter += 1
		local nodeName = string.format("%s_Coin_%d", spawnerPart.Name, i)
		createCoinNode(nodeName, pos, zoneTier)
	end

	-- Only hide the part if the builder explicitly requested it via an attribute
	if spawnerPart:GetAttribute("HidePart") == true then
		spawnerPart.Transparency = 1
		spawnerPart.CanCollide = false
	end

	print(string.format("[CoinSpawner] Configured spawner %q: spawned %d coin(s) in Zone %d (spacing: %.1f studs)", spawnerPart.Name, #spawnPoints, zoneTier, spacing))
end


--- Delegates pickup validation to centralized CoinService
function CoinSpawner.HandlePickup(player: Player, coinNode: BasePart)
	CoinService.CollectArenaNode(player, coinNode)
end

--- Initializes CollectionService listeners and processes map spawners
function CoinSpawner.Init()
	local existingFolder = Workspace:FindFirstChild("CoinNodes") :: Folder?
	if not existingFolder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "CoinNodes"
		newFolder.Parent = Workspace
		CoinNodesFolder = newFolder
	else
		CoinNodesFolder = existingFolder
	end

	local spawnerCfg = Config.COIN_SPAWNER or {}
	local primaryTag = spawnerCfg.TAG or "CoinSpawnSurface"
	local tagsToWatch = { primaryTag }
	if spawnerCfg.ALIASES then
		for _, alias in ipairs(spawnerCfg.ALIASES) do
			table.insert(tagsToWatch, alias)
		end
	end

	local totalFound = 0
	for _, tag in ipairs(tagsToWatch) do
		for _, spawner in ipairs(CollectionService:GetTagged(tag)) do
			if spawner:IsA("BasePart") then
				processSpawnerPart(spawner)
				totalFound += 1
			end
		end

		CollectionService:GetInstanceAddedSignal(tag):Connect(function(spawner)
			if spawner:IsA("BasePart") then
				processSpawnerPart(spawner)
			end
		end)
	end

	-- Fallback: If no builder spawners exist yet in Workspace, create default floor nodes
	if totalFound == 0 then
		print(string.format("[CoinSpawner] No parts tagged %q found. Spawning default fallback zone nodes.", primaryTag))
		local fallbackPositions = {
			-- Zone 1 (Z = -50, Y = 10)
			{ Pos = Vector3.new(-8, 10, -50), Zone = 1 },
			{ Pos = Vector3.new(0, 10, -50), Zone = 1 },
			{ Pos = Vector3.new(8, 10, -50), Zone = 1 },

			-- Zone 2 (Z = -90, Y = 19)
			{ Pos = Vector3.new(-8, 19, -90), Zone = 2 },
			{ Pos = Vector3.new(0, 19, -90), Zone = 2 },
			{ Pos = Vector3.new(8, 19, -90), Zone = 2 },

			-- Zone 3 (Z = -130, Y = 27)
			{ Pos = Vector3.new(-8, 27, -130), Zone = 3 },
			{ Pos = Vector3.new(0, 27, -130), Zone = 3 },
			{ Pos = Vector3.new(8, 27, -130), Zone = 3 },
		}

		for _, entry in ipairs(fallbackPositions) do
			coinNodeCounter += 1
			createCoinNode("Fallback_Coin_" .. coinNodeCounter, entry.Pos, entry.Zone)
		end
	end

	print(string.format("[CoinSpawner] Initialized. Total active coin nodes created: %d", coinNodeCounter))
end

return CoinSpawner

