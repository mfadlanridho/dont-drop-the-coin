--!nonstrict
--[[
    DataStoreManager.luau
    Handles player session data loading, profile reconciliation, auto-saving, and dupe-proof persistence using ProfileStore.
    Location: src/server/Services/DataStoreManager.luau (Syncs to ServerScriptService.Server.Services.DataStoreManager)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ServerScriptService = game:GetService("ServerScriptService")
local ServerPackages = ServerScriptService:WaitForChild("ServerPackages")
local ProfileStore = require(ServerPackages:WaitForChild("ProfileStore") :: ModuleScript)

local PlayerProfileStore = ProfileStore.New(
	Config.DATASTORE_KEY,
	Config.DEFAULT_DATA
)

local Profiles = {}
local DataStoreManager = {}

-- Load Profile on Player Join
local function onPlayerAdded(player: Player)
	local profileKey = "Player_" .. player.UserId
	local profile = PlayerProfileStore:StartSessionAsync(profileKey, {
		Steal = true,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Your session ended or was logged into from another device.")
		end)

		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile
			print(string.format("[DataStoreManager] Profile loaded & active for %s (UserId: %d)", player.Name, player.UserId))
		else
			profile:EndSession()
		end
	else
		player:Kick("Could not load your player data. Please rejoin.")
	end
end

-- Release Profile on Player Leave
local function onPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
		Profiles[player] = nil
		print(string.format("[DataStoreManager] Profile session ended for %s", player.Name))
	end
end

-- Public API: Get Active Profile Data
function DataStoreManager.GetData(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		return profile.Data
	end
	return nil
end

-- Public API: Add Permanent Banked Cash
function DataStoreManager.AddBankedCash(player: Player, amount: number): boolean
	local profile = Profiles[player]
	if profile ~= nil and profile.Data and amount > 0 then
		profile.Data.Coins = (profile.Data.Coins or 0) + amount
		profile.Data.TotalBanked = (profile.Data.TotalBanked or 0) + amount
		return true
	end
	return false
end

-- Save All Active Sessions (BindToClose Handler)
function DataStoreManager.SaveAll()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerRemoving(player)
	end
end

-- Initialize Listeners
function DataStoreManager.Init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayerAdded, player)
	end)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		print("[DataStoreManager] Server shutting down, releasing all ProfileStore sessions...")
		DataStoreManager.SaveAll()
	end)
end

return DataStoreManager
