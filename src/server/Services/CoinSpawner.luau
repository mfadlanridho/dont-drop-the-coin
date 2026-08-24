--!nonstrict
--[[
    CoinSpawner.luau
    Manages zone coin node spawning, pickup distance anti-cheat validation, and node respawning.
    Location: src/server/Services/CoinSpawner.luau (Syncs to ServerScriptService.Server.Services.CoinSpawner)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Services = script.Parent
local StackServer = require(Services:WaitForChild("StackServer"))

local CoinSpawner = {}
local CoinNodesFolder: Folder

-- Handle Pickup Request
local function handlePickup(player: Player, coinNode: Part)
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

	print(string.format("[CoinSpawner] %s picked up coin in Zone %d (New Stack: %d)", player.Name, zoneTier, newStack))

	-- Respawn Timer
	task.delay(Config.COIN_NODE_RESPAWN_TIME, function()
		if coinNode and coinNode.Parent then
			coinNode:SetAttribute("Active", true)
			coinNode.Transparency = 0
			coinNode.CanTouch = true
		end
	end)
end

-- Initialize Coin Spawner
function CoinSpawner.Init()
	CoinNodesFolder = Workspace:FindFirstChild("CoinNodes") :: Folder
	if not CoinNodesFolder then
		CoinNodesFolder = Instance.new("Folder")
		CoinNodesFolder.Name = "CoinNodes"
		CoinNodesFolder.Parent = Workspace
	end

	-- Create Initial Test Coin Nodes if folder is empty
	if #CoinNodesFolder:GetChildren() == 0 then
		local testPositions = {
			{ Pos = Vector3.new(0, 3, 10), Zone = 1 },
			{ Pos = Vector3.new(5, 3, 15), Zone = 1 },
			{ Pos = Vector3.new(-5, 3, 20), Zone = 1 },
			{ Pos = Vector3.new(0, 15, 30), Zone = 2 },
			{ Pos = Vector3.new(0, 30, 45), Zone = 3 },
		}

		for i, data in ipairs(testPositions) do
			local node = Instance.new("Part")
			node.Name = "CoinNode_" .. i
			node.Shape = Enum.PartType.Cylinder
			node.Size = Vector3.new(0.5, 2.5, 2.5)
			node.Position = data.Pos
			node.Orientation = Vector3.new(0, 0, 90)
			node.Color = Color3.fromRGB(255, 223, 0)
			node.Material = Enum.Material.Neon
			node.Anchored = true
			node.CanCollide = false
			node:SetAttribute("Active", true)
			node:SetAttribute("ZoneTier", data.Zone)
			node.Parent = CoinNodesFolder

			node.Touched:Connect(function(hit)
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if player then
					handlePickup(player, node)
				end
			end)
		end
	end

	-- Listen for Remote Pickups
	local pickupEvent = Remotes.Get("PickupCoin")
	if pickupEvent then
		pickupEvent.OnServerEvent:Connect(function(player, coinNode)
			if typeof(coinNode) == "Instance" and coinNode:IsDescendantOf(CoinNodesFolder) then
				handlePickup(player, coinNode)
			end
		end)
	end
end

return CoinSpawner
