--!nonstrict
--[[
    StackServer.luau
    Manages server-side player head stack state, updates leaderstats.Stack, and replicates stack counts to clients with zero physics assembly impact.
    Location: src/server/Services/StackServer.luau (Syncs to ServerScriptService.Server.Services.StackServer)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerStacks = {}
local StackServer = {}

-- Helper to sync leaderstats.Stack IntValue
local function syncLeaderstatsStack(player: Player, count: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stackVal = leaderstats:FindFirstChild("Stack") :: IntValue
		if stackVal then
			stackVal.Value = count
		end
	end
end

-- Add Coin to Player Stack
function StackServer.AddCoin(player: Player, zoneMultiplier: number?): number
	local userId = player.UserId
	if not PlayerStacks[userId] then
		PlayerStacks[userId] = { Count = 0 }
	end

	local stackData = PlayerStacks[userId]
	stackData.Count = stackData.Count + 1

	-- Replicate Stack Update to All Clients & Leaderstats
	syncLeaderstatsStack(player, stackData.Count)

	local updateEvent = Remotes.Get("UpdateStack")
	if updateEvent then
		updateEvent:FireAllClients(player, stackData.Count)
	end

	return stackData.Count
end

-- Set Explicit Stack Count (for testing/debug)
function StackServer.SetStackCount(player: Player, count: number): number
	local userId = player.UserId
	local newCount = math.max(0, count)
	PlayerStacks[userId] = { Count = newCount }

	-- Replicate Stack Update to All Clients & Leaderstats
	syncLeaderstatsStack(player, newCount)

	local updateEvent = Remotes.Get("UpdateStack")
	if updateEvent then
		updateEvent:FireAllClients(player, newCount)
	end

	return newCount
end

-- Clear Player Stack (used on banking or ragdoll explosion)
function StackServer.ClearStack(player: Player): number
	local userId = player.UserId
	local stackData = PlayerStacks[userId]
	local previousCount = 0

	if stackData then
		previousCount = stackData.Count
		PlayerStacks[userId] = { Count = 0 }
	end

	-- Replicate Clear Event to All Clients & Leaderstats
	syncLeaderstatsStack(player, 0)

	local updateEvent = Remotes.Get("UpdateStack")
	if updateEvent then
		updateEvent:FireAllClients(player, 0)
	end

	return previousCount
end

-- Get Stack Count
function StackServer.GetStackCount(player: Player): number
	local stackData = PlayerStacks[player.UserId]
	return stackData and stackData.Count or 0
end

-- Clean up on player leave and sync initial stacks
function StackServer.Init()
	Players.PlayerRemoving:Connect(function(player)
		PlayerStacks[player.UserId] = nil
	end)

	local function onCharacterSpawned(player: Player)
		-- Start player with 3 coins for immediate visual stack & combat test
		task.defer(function()
			StackServer.SetStackCount(player, 3)
		end)
	end

	local function onPlayerJoined(player: Player)
		player.CharacterAdded:Connect(function()
			onCharacterSpawned(player)
		end)
		if player.Character then
			onCharacterSpawned(player)
		end
	end

	Players.PlayerAdded:Connect(onPlayerJoined)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayerJoined(p)
	end

	print("[StackServer] Initialized with real-time leaderstats.Stack syncing.")
end

return StackServer
