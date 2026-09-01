--!nonstrict
--[[
    CoinSpawner.luau
    Manages zone coin node spawning and placement across map floors.
    Delegates pickup validation, audio, and node respawning to CoinService.luau.
    Location: src/server/Services/CoinSpawner.luau (Syncs to ServerScriptService.Server.Services.CoinSpawner)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TemplateUtil = require(Shared:WaitForChild("Utils"):WaitForChild("TemplateUtil"))

local Services = script.Parent
local CoinService = require(Services:WaitForChild("CoinService"))

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

-- Handle Pickup Request (Delegates to centralized CoinService)
function CoinSpawner.HandlePickup(player: Player, coinNode: BasePart)
	CoinService.CollectArenaNode(player, coinNode)
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

		-- Zone 3 Coins (Z = -130, Y = 27)
		-- { Pos = Vector3.new(-8, 27, -130), Zone = 3 },
		-- { Pos = Vector3.new(0, 27, -130), Zone = 3 },
		-- { Pos = Vector3.new(8, 27, -130), Zone = 3 },
	}

	for i, entry in ipairs(alignedPositions) do
		createCoinNode("CoinNode_" .. i, entry.Pos, entry.Zone)
	end

	print("[CoinSpawner] Initialized coin nodes across map floors.")
end

return CoinSpawner
