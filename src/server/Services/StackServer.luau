--!nonstrict
--[[
    StackServer.luau
    Manages server-side player head stack state and replicates stack counts to clients with zero physics assembly impact.
    Location: src/server/Services/StackServer.luau (Syncs to ServerScriptService.Server.Services.StackServer)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerStacks = {}
local StackServer = {}

-- Add Coin to Player Stack
function StackServer.AddCoin(player: Player, zoneMultiplier: number?): number
	local userId = player.UserId
	if not PlayerStacks[userId] then
		PlayerStacks[userId] = { Count = 0 }
	end

	local stackData = PlayerStacks[userId]
	stackData.Count = stackData.Count + 1

	-- Replicate Stack Update to All Clients (For local visual rendering)
	local updateEvent = Remotes.Get("UpdateStack")
	if updateEvent then
		updateEvent:FireAllClients(player, stackData.Count)
	end

	return stackData.Count
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

	-- Replicate Clear Event to All Clients
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

-- Clean up on player leave
function StackServer.Init()
	Players.PlayerRemoving:Connect(function(player)
		PlayerStacks[player.UserId] = nil
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			StackServer.ClearStack(player)
		end)
	end)
end

return StackServer
