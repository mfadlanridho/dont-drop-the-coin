--!nonstrict
--[[
    CoinSpawner.luau
    Manages zone coin node spawning, pickup distance anti-cheat validation, and node respawning across map floors.
    Clones physical CoinTemplate from ReplicatedStorage.Templates.CoinTemplate.
    Location: src/server/Services/CoinSpawner.luau (Syncs to ServerScriptService.Server.Services.CoinSpawner)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local TemplateUtil = require(Shared:WaitForChild("Utils"):WaitForChild("TemplateUtil"))

local Services = script.Parent
local StackServer = require(Services:WaitForChild("StackServer"))

local CoinSpawner = {}
local CoinNodesFolder: Folder

-- Helper to create a physical floating coin node by cloning CoinTemplate
local function createCoinNode(name: string, pos: Vector3, zoneTier: number): BasePart
	local node = TemplateUtil.CloneCoinTemplate()
	node.Name = name
	node.Position = pos
	node.Anchored = true
	node.CanCollide = false
	node:SetAttribute("Active", true)
	node:SetAttribute("ZoneTier", zoneTier)
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

-- Handle Pickup Request
function CoinSpawner.HandlePickup(player: Player, coinNode: BasePart)
	if not coinNode or not coinNode:IsA("BasePart") or not coinNode:GetAttribute("Active") then
		return
	end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	-- Server Anti-Cheat Distance Validation
	local distance = (hrp.Position - coinNode.Position).Magnitude
	if distance > 15 then
		warn(string.format("[Anti-Cheat] %s attempted pickup from invalid distance: %.2f studs", player.Name, distance))
		return
	end

	-- Deactivate Node
	coinNode:SetAttribute("Active", false)
	coinNode.Transparency = 1
	coinNode.CanTouch = false

	-- Award Stack Count
	local zoneTier = coinNode:GetAttribute("ZoneTier") or 1
	local newStack = StackServer.AddCoin(player, zoneTier)

	-- Fire Sound Event with Pitch Combo to Client
	local soundRemote = Remotes.Get("PlaySound")
	if soundRemote then
		soundRemote:FireClient(player, "CoinPickupCombo", hrp)
	end

	print(string.format("[CoinSpawner] %s picked up coin in Zone %d (New Stack: %d)", player.Name, zoneTier, newStack))

	-- Respawn Timer (5 seconds)
	task.delay(Config.COIN_NODE_RESPAWN_TIME or 5, function()
		if coinNode and coinNode.Parent then
			coinNode:SetAttribute("Active", true)
			coinNode.Transparency = 0
			coinNode.CanTouch = true
		end
	end)
end

-- Initialize Coin Spawner & Populate Aligned Floor Nodes
function CoinSpawner.Init()
	local existingFolder = Workspace:FindFirstChild("CoinNodes") :: Folder?
	if not existingFolder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "CoinNodes"
		newFolder.Parent = Workspace
		CoinNodesFolder = newFolder
	else
		existingFolder:ClearAllChildren()
		CoinNodesFolder = existingFolder
	end

	-- Populate Aligned Floor Coin Nodes
	-- will need to replace later with actual area boundaries spawning defined by builders
	local alignedPositions = {
		-- Zone 1 Coins (Z = -50, Y = 10)
		{ Pos = Vector3.new(-8, 10, -50), Zone = 1 },
		{ Pos = Vector3.new(0, 10, -50), Zone = 1 },
		{ Pos = Vector3.new(8, 10, -50), Zone = 1 },

		-- Zone 2 Coins (Z = -90, Y = 19)
		{ Pos = Vector3.new(-8, 19, -90), Zone = 2 },
		{ Pos = Vector3.new(0, 19, -90), Zone = 2 },
		{ Pos = Vector3.new(8, 19, -90), Zone = 2 },

		-- -- Zone 3 Coins (Z = -130, Y = 27)
		-- { Pos = Vector3.new(-8, 27, -130), Zone = 3 },
		-- { Pos = Vector3.new(0, 27, -130), Zone = 3 },
		-- { Pos = Vector3.new(8, 27, -130), Zone = 3 },
	}

	for i, data in ipairs(alignedPositions) do
		createCoinNode("CoinNode_Zone" .. data.Zone .. "_" .. i, data.Pos, data.Zone)
	end

	-- Listen for Remote Pickups
	local pickupEvent = Remotes.Get("PickupCoin")
	if pickupEvent then
		pickupEvent.OnServerEvent:Connect(function(player, coinNode)
			if typeof(coinNode) == "Instance" and coinNode:IsA("BasePart") and coinNode:IsDescendantOf(CoinNodesFolder) then
				CoinSpawner.HandlePickup(player, coinNode)
			end
		end)
	end

	print("[CoinSpawner] Initialized coin nodes cloned from ReplicatedStorage.Templates.CoinTemplate.")
end

return CoinSpawner
