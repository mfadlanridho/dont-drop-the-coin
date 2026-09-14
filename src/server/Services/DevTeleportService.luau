--!strict
--[[
    DevTeleportService.luau
    Handles developer-only map teleportation requests across zones and the base podium.
    Performs server-authoritative physics momentum reset and precise safe landing surface resolution.
    Location: src/server/Services/DevTeleportService.luau (Syncs to ServerScriptService.Server.Services.DevTeleportService)
--]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DevTeleportService = {}

-- Checks if a player is authorized to use developer teleportation
local function isAuthorized(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end

	-- Check creator ownership
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId then
		return true
	end

	-- Check developer whitelist in Config
	local devIds = (Config :: any).DEVELOPER_IDS
	if typeof(devIds) == "table" and table.find(devIds, player.UserId) ~= nil then
		return true
	end

	return false
end

-- Safely raycasts down to find the exact top surface Y of a part
local function getTopSurfaceCFrame(part: BasePart): CFrame
	local origin = Vector3.new(part.Position.X, part.Position.Y + 25, part.Position.Z)
	local rayDir = Vector3.new(0, -50, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { part }

	local hit = Workspace:Raycast(origin, rayDir, params)
	if hit then
		return CFrame.new(hit.Position + Vector3.new(0, 3.5, 0))
	end

	return CFrame.new(part.Position.X, part.Position.Y + (part.Size.Y / 2) + 3.5, part.Position.Z)
end

-- Resolves a destination key to a world CFrame
local function resolveDestination(destinationKey: string): CFrame?
	if destinationKey == "Podium" or destinationKey == "BaseFloor" then
		local basePart = Workspace:FindFirstChild("FoundCapFace_154")
			or Workspace:FindFirstChild("PodiumFill")
			or Workspace:FindFirstChild("LobbyFloorBase")
		if basePart and basePart:IsA("BasePart") then
			return getTopSurfaceCFrame(basePart)
		end
		return CFrame.new(-393.45, 19.92, 50.58)
	end

	if destinationKey == "Spawn" then
		local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
		if spawnLoc then
			return CFrame.new(spawnLoc.Position + Vector3.new(0, 3.5, 0))
		end
		return CFrame.new(0, 3.5, 0)
	end

	-- Zone pattern: "Zone1", "Zone2", ... "Zone10"
	local zoneNum = string.match(destinationKey, "Zone(%d+)")
	if zoneNum then
		local targetZoneModel: Instance? = nil
		for _, child in ipairs(Workspace:GetChildren()) do
			if child.Name:match("^Zone" .. zoneNum .. "_") or child.Name == destinationKey then
				targetZoneModel = child
				break
			end
		end

		if targetZoneModel then
			local zoneFloor = targetZoneModel:FindFirstChild("ZoneFloor")
			local slab = zoneFloor and (zoneFloor:FindFirstChild("ZoneFloorSlab") or zoneFloor:FindFirstChildOfClass("BasePart"))
			if slab and slab:IsA("BasePart") then
				return getTopSurfaceCFrame(slab)
			end

			if targetZoneModel:IsA("Model") then
				local cf, size = targetZoneModel:GetBoundingBox()
				return CFrame.new(cf.Position.X, cf.Position.Y - (size.Y / 2) + 4, cf.Position.Z)
			end
		end
	end

	-- Dynamic CollectionService "DevTeleport" tagged parts
	for _, taggedPart in ipairs(CollectionService:GetTagged("DevTeleport")) do
		if taggedPart:IsA("BasePart") and taggedPart.Name == destinationKey then
			return getTopSurfaceCFrame(taggedPart)
		end
	end

	return nil
end

-- Performs the teleportation with velocity reset
function DevTeleportService.TeleportPlayer(player: Player, destinationKey: string): boolean
	if not isAuthorized(player) then
		warn(string.format("[DevTeleportService] Unauthorized teleport attempt by %s (%d)", player.Name, player.UserId))
		return false
	end

	local targetCFrame = resolveDestination(destinationKey)
	if not targetCFrame then
		warn(string.format("[DevTeleportService] Could not resolve destination: %q", destinationKey))
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then
		return false
	end

	-- Momentum Reset: Zero out linear & angular velocities
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	-- Smoothly position character safely above floor
	character:PivotTo(targetCFrame)

	print(string.format("[DevTeleportService] 🚀 Teleported %s to %q at (%d, %d, %d)",
		player.Name,
		destinationKey,
		math.round(targetCFrame.Position.X),
		math.round(targetCFrame.Position.Y),
		math.round(targetCFrame.Position.Z)
	))

	return true
end

function DevTeleportService.Init()
	local devTeleportRemote = Remotes.Get("DevTeleport")
	if devTeleportRemote then
		devTeleportRemote.OnServerEvent:Connect(function(player: Player, destinationKey: any)
			if typeof(destinationKey) == "string" then
				DevTeleportService.TeleportPlayer(player, destinationKey)
			end
		end)
	end

	print("[DevTeleportService] Initialized DevTeleportService remote listener successfully!")
end

return DevTeleportService
