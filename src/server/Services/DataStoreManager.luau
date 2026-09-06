--!nonstrict
--[[
    DataStoreManager.luau
    Handles player session data loading, profile reconciliation, auto-saving, and dupe-proof persistence using ProfileStore.
    Location: src/server/Services/DataStoreManager.luau (Syncs to ServerScriptService.Server.Services.DataStoreManager)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Signal = require(ReplicatedStorage.Packages.SignalModule)

local ServerPackages = ServerScriptService:WaitForChild("ServerPackages")
local ProfileStore = require(ServerPackages:WaitForChild("ProfileStore") :: ModuleScript)

local MAX_COINS = 2_147_483_647
local MAX_TOTAL_BANKED = 2_147_483_647

local PlayerProfileStore = ProfileStore.New(
	Config.DATASTORE_KEY,
	Config.DEFAULT_DATA
)

local Profiles = {}
local loadingPlayers = {}

local DataStoreManager = {}
DataStoreManager.PlayerLoaded = Signal.new()

local function getProfile(player: any)
	if not player then
		return nil
	end

	local profile = Profiles[player]
	if profile then
		return profile
	end

	if typeof(player) == "table" and player.UserId then
		return Profiles[player.UserId]
	end

	return nil
end

local function isSessionValid(profile: any): boolean
	return profile ~= nil and profile.Data ~= nil
end

-- Load Profile on Player Join
function DataStoreManager.LoadPlayer(player: any)
	if not player or not player.UserId then
		return false, "InvalidPlayer"
	end

	local existingProfile = getProfile(player)
	if existingProfile and existingProfile.Data then
		return true, existingProfile.Data
	end

	-- Handle concurrent load calls for the same player
	if loadingPlayers[player] then
		while loadingPlayers[player] do
			task.wait(0.1)
		end
		local loadedProfile = getProfile(player)
		if loadedProfile and loadedProfile.Data then
			return true, loadedProfile.Data
		else
			return false, "LoadFailedInOtherThread"
		end
	end

	loadingPlayers[player] = true

	local profileKey = "Player_" .. tostring(player.UserId)
	local profile = PlayerProfileStore:StartSessionAsync(profileKey, {
		Steal = true,
	})

	loadingPlayers[player] = nil

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		local isRealPlayer = typeof(player) == "Instance" and player:IsA("Player")

		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			if typeof(player.UserId) == "number" then
				Profiles[player.UserId] = nil
			end
			if isRealPlayer and player:IsDescendantOf(Players) then
				player:Kick("Your session ended or was logged into from another device.")
			end
		end)

		if not isRealPlayer or player:IsDescendantOf(Players) then
			Profiles[player] = profile
			if typeof(player.UserId) == "number" then
				Profiles[player.UserId] = profile
			end

			print(string.format("[DataStoreManager] Profile loaded & active for %s (UserId: %s)", tostring(player.Name), tostring(player.UserId)))
			DataStoreManager.PlayerLoaded:Fire(player, profile.Data)

			return true, profile.Data
		else
			profile:EndSession()
			return false, "PlayerLeftDuringLoad"
		end
	else
		local isRealPlayer = typeof(player) == "Instance" and player:IsA("Player")
		if isRealPlayer and player:IsDescendantOf(Players) then
			player:Kick("Could not load your player data. Please rejoin.")
		end
		warn(string.format("[DataStoreManager] Could not start ProfileStore session for %s (UserId: %s)", tostring(player.Name), tostring(player.UserId)))
		return false, "SessionLoadFailed"
	end
end

-- Listen for Player Profile Load (Supports both already-loaded and pending players)
function DataStoreManager.OnPlayerLoaded(player: Player, callback: (data: any) -> ())
	if not player then
		return
	end

	if DataStoreManager.IsLoaded(player) then
		task.spawn(callback, DataStoreManager.GetData(player))
		return
	end

	local conn: any
	local removingConn: RBXScriptConnection?

	local function cleanup()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		if removingConn then
			removingConn:Disconnect()
			removingConn = nil
		end
	end

	conn = DataStoreManager.PlayerLoaded:Connect(function(loadedPlayer, data)
		if loadedPlayer == player then
			cleanup()
			if typeof(player) ~= "Instance" or player.Parent then
				callback(data)
			end
		end
	end)

	if typeof(player) == "Instance" and player:IsA("Player") then
		removingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
			if leavingPlayer == player then
				cleanup()
			end
		end)
	end
end

-- Public API: Check if Player Profile is Loaded
function DataStoreManager.IsLoaded(player: any): boolean
	local profile = getProfile(player)
	return profile ~= nil and profile.Data ~= nil
end

-- Public API: Mark session dirty (No-op in ProfileStore as data is directly synced, kept for backward compatibility)
function DataStoreManager.MarkDirty(player: any): boolean
	return DataStoreManager.IsLoaded(player)
end

-- Public API: Get Active Profile Data
function DataStoreManager.GetData(player: any)
	local profile = getProfile(player)
	if profile ~= nil then
		return profile.Data
	end
	return nil
end

-- Public API: Add Permanent Banked Cash
function DataStoreManager.AddBankedCash(player: any, amount: number): boolean
	if type(amount) ~= "number" or amount <= 0 or amount ~= amount then
		return false
	end

	amount = math.floor(amount)

	local profile = getProfile(player)
	if not isSessionValid(profile) then
		return false
	end

	local data = profile.Data
	local currentCoins = data.Coins or 0
	local currentTotalBanked = data.TotalBanked or 0

	if currentCoins + amount > MAX_COINS or currentTotalBanked + amount > MAX_TOTAL_BANKED then
		return false
	end

	data.Coins = currentCoins + amount
	data.TotalBanked = currentTotalBanked + amount

	return true
end

-- Public API: Remove Coins from Wallet
function DataStoreManager.RemoveCoins(player: any, amount: number): boolean
	if type(amount) ~= "number" or amount <= 0 or amount ~= amount then
		return false
	end

	amount = math.floor(amount)

	local profile = getProfile(player)
	if not isSessionValid(profile) then
		return false
	end

	local data = profile.Data
	local currentCoins = data.Coins or 0

	if currentCoins < amount then
		return false
	end

	data.Coins = currentCoins - amount
	return true
end

-- Public API: Explicitly Set Coins
function DataStoreManager.SetCoins(player: any, amount: number): boolean
	if type(amount) ~= "number" or amount < 0 or amount ~= amount then
		return false
	end

	amount = math.floor(amount)

	if amount > MAX_COINS then
		return false
	end

	local profile = getProfile(player)
	if not isSessionValid(profile) then
		return false
	end

	profile.Data.Coins = amount
	return true
end

-- Public API: Get Current Coins
function DataStoreManager.GetCoins(player: any): number?
	local data = DataStoreManager.GetData(player)
	if not data then
		return nil
	end
	return data.Coins
end

-- Public API: Get Total Banked Lifetime Coins
function DataStoreManager.GetTotalBanked(player: any): number?
	local data = DataStoreManager.GetData(player)
	if not data then
		return nil
	end
	return data.TotalBanked
end

-- Save / Release Single Player Profile
function DataStoreManager.SavePlayer(player: any, release: boolean?)
	local profile = getProfile(player)
	if not profile then
		return false, "NoSession"
	end

	if release == true then
		profile:EndSession()
		Profiles[player] = nil
		if typeof(player.UserId) == "number" then
			Profiles[player.UserId] = nil
		end
		return true
	else
		profile:Save()
		return true
	end
end

-- Release Single Player Profile
function DataStoreManager.ReleasePlayer(player: any)
	return DataStoreManager.SavePlayer(player, true)
end

-- Save All Active Sessions (Server Shutdown / BindToClose)
function DataStoreManager.SaveAll(): boolean
	local activeProfiles = {}
	for key, profile in pairs(Profiles) do
		if typeof(key) == "Instance" or typeof(key) == "table" then
			table.insert(activeProfiles, profile)
		end
	end

	for _, profile in ipairs(activeProfiles) do
		pcall(function()
			profile:EndSession()
		end)
	end

	table.clear(Profiles)
	return true
end

-- Initialize Listeners
function DataStoreManager.Init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(DataStoreManager.LoadPlayer, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		DataStoreManager.ReleasePlayer(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(DataStoreManager.LoadPlayer, player)
	end

	game:BindToClose(function()
		print("[DataStoreManager] Server shutting down, releasing all ProfileStore sessions...")
		DataStoreManager.SaveAll()
	end)
end

return DataStoreManager