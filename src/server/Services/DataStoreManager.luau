--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.SignalModule)

local DataStoreManager = {}
DataStoreManager.PlayerLoaded = Signal.new()

local STORE_NAME = "PlayerData_V2"
local AUTOSAVE_INTERVAL = 60
local SAVE_RETRIES = 5
local RETRY_BASE_DELAY = 2
local SESSION_TIMEOUT = 180
local MAX_COINS = 2_147_483_647
local MAX_TOTAL_BANKED = 2_147_483_647

local Store = DataStoreService:GetDataStore(STORE_NAME)

local DEFAULT_DATA = {
	DataVersion = 2,
	Coins = 0,
	TotalBanked = 0,
}

local sessions = {}
local shuttingDown = false

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}

	for key, child in pairs(value) do
		copy[key] = deepCopy(child)
	end

	return copy
end

local function reconcile(data, defaults)
	if type(data) ~= "table" then
		data = {}
	end

	for key, defaultValue in pairs(defaults) do
		if data[key] == nil then
			data[key] = deepCopy(defaultValue)
		elseif type(defaultValue) == "table" then
			data[key] = reconcile(data[key], defaultValue)
		end
	end

	return data
end

local function sanitize(data)
	data = reconcile(data, DEFAULT_DATA)

	if type(data.Coins) ~= "number" or data.Coins ~= data.Coins then
		data.Coins = 0
	end

	if type(data.TotalBanked) ~= "number" or data.TotalBanked ~= data.TotalBanked then
		data.TotalBanked = 0
	end

	data.Coins = math.clamp(math.floor(data.Coins), 0, MAX_COINS)
	data.TotalBanked = math.clamp(math.floor(data.TotalBanked), 0, MAX_TOTAL_BANKED)

	if type(data.DataVersion) ~= "number" then
		data.DataVersion = DEFAULT_DATA.DataVersion
	end

	return data
end

local function migrate(data)
	data = sanitize(data)

	if data.DataVersion < 2 then
		data.DataVersion = 2
	end

	return data
end

local function getKey(userId)
	return "Player_" .. tostring(userId)
end

local function isSessionValid(session)
	return session ~= nil and session.Data ~= nil and session.LockId ~= nil
end

local function waitForRetry(attempt)
	task.wait(RETRY_BASE_DELAY * (2 ^ (attempt - 1)))
end

local function executeWithRetries(callback)
	local lastError

	for attempt = 1, SAVE_RETRIES do
		local success, result = pcall(callback)

		if success then
			return true, result
		end

		lastError = result

		if attempt < SAVE_RETRIES then
			waitForRetry(attempt)
		end
	end

	return false, lastError
end

local function acquireSession(player)
	local key = getKey(player.UserId)
	local lockId = game.JobId .. ":" .. tostring(os.time())

	local success, result = executeWithRetries(function()
		return Store:UpdateAsync(key, function(oldData)
			oldData = migrate(oldData)

			local existingLock = oldData.__SessionLock
			local existingTime = oldData.__SessionTime or 0
			local currentTime = os.time()

			if existingLock and existingLock ~= lockId then
				if currentTime - existingTime < SESSION_TIMEOUT then
					return nil
				end
			end

			oldData.__SessionLock = lockId
			oldData.__SessionTime = currentTime

			return oldData
		end)
	end)

	if not success then
		return false, result
	end

	if result == nil then
		return false, "SessionLocked"
	end

	result = migrate(result)

	result.__SessionLock = nil
	result.__SessionTime = nil

	local session = {
		Player = player,
		Data = result,
		LockId = lockId,
		Dirty = false,
		Saving = false,
		Loaded = true,
	}

	sessions[player.UserId] = session

	return true, session
end

local function saveSession(session, release)
	if not isSessionValid(session) then
		return false, "InvalidSession"
	end

	if session.Saving then
		return false, "AlreadySaving"
	end

	session.Saving = true

	local player = session.Player
	local key = getKey(player.UserId)
	local lockId = session.LockId
	local dataToSave = deepCopy(session.Data)

	dataToSave = migrate(dataToSave)

	dataToSave.__SessionLock = lockId
	dataToSave.__SessionTime = os.time()

	local success, result = executeWithRetries(function()
		return Store:UpdateAsync(key, function(oldData)
			oldData = migrate(oldData)

			local existingLock = oldData.__SessionLock

			if existingLock ~= lockId then
				return nil
			end

			if release then
				dataToSave.__SessionLock = nil
				dataToSave.__SessionTime = nil
			else
				dataToSave.__SessionTime = os.time()
			end

			return dataToSave
		end)
	end)

	session.Saving = false

	if not success then
		return false, result
	end

	if result == nil then
		return false, "SessionOwnershipLost"
	end

	session.Dirty = false

	if release then
		session.Loaded = false
	end

	return true
end

function DataStoreManager.LoadPlayer(player)
	if sessions[player.UserId] then
		return true, sessions[player.UserId].Data
	end

	local success, result = acquireSession(player)

	if not success then
		warn("[DataStoreManager] Failed to load " .. player.Name .. ": " .. tostring(result))
		return false, result
	end

	print("[DataStoreManager] Loaded data for " .. player.Name)
	DataStoreManager.PlayerLoaded:Fire(player, result.Data)

	return true, result.Data
end

function DataStoreManager.OnPlayerLoaded(player: Player, callback: (data: any) -> ())
	if not player.Parent then return end

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
			if player.Parent then
				callback(data)
			end
		end
	end)

	removingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			cleanup()
		end
	end)
end

function DataStoreManager.GetData(player)
	local session = sessions[player.UserId]

	if not session or not session.Loaded then
		return nil
	end

	return session.Data
end

function DataStoreManager.IsLoaded(player)
	local session = sessions[player.UserId]

	return session ~= nil and session.Loaded == true
end

function DataStoreManager.MarkDirty(player)
	local session = sessions[player.UserId]

	if not session or not session.Loaded then
		return false
	end

	session.Dirty = true

	return true
end

function DataStoreManager.AddBankedCash(player, amount)
	if type(amount) ~= "number" then
		return false
	end

	if amount <= 0 or amount ~= amount then
		return false
	end

	amount = math.floor(amount)

	local session = sessions[player.UserId]

	if not isSessionValid(session) then
		return false
	end

	local data = session.Data

	if data.Coins + amount > MAX_COINS then
		return false
	end

	if data.TotalBanked + amount > MAX_TOTAL_BANKED then
		return false
	end

	data.Coins += amount
	data.TotalBanked += amount

	session.Dirty = true

	return true
end

function DataStoreManager.RemoveCoins(player, amount)
	if type(amount) ~= "number" then
		return false
	end

	if amount <= 0 or amount ~= amount then
		return false
	end

	amount = math.floor(amount)

	local session = sessions[player.UserId]

	if not isSessionValid(session) then
		return false
	end

	if session.Data.Coins < amount then
		return false
	end

	session.Data.Coins -= amount
	session.Dirty = true

	return true
end

function DataStoreManager.SetCoins(player, amount)
	if type(amount) ~= "number" then
		return false
	end

	if amount < 0 or amount ~= amount then
		return false
	end

	amount = math.floor(amount)

	if amount > MAX_COINS then
		return false
	end

	local session = sessions[player.UserId]

	if not isSessionValid(session) then
		return false
	end

	session.Data.Coins = amount
	session.Dirty = true

	return true
end

function DataStoreManager.GetCoins(player)
	local data = DataStoreManager.GetData(player)

	if not data then
		return nil
	end

	return data.Coins
end

function DataStoreManager.GetTotalBanked(player)
	local data = DataStoreManager.GetData(player)

	if not data then
		return nil
	end

	return data.TotalBanked
end

function DataStoreManager.SavePlayer(player, release)
	local session = sessions[player.UserId]

	if not session then
		return false, "NoSession"
	end

	local success, result = saveSession(session, release == true)

	if release then
		sessions[player.UserId] = nil
	end

	if not success then
		warn("[DataStoreManager] Failed to save " .. player.Name .. ": " .. tostring(result))
	end

	return success, result
end

function DataStoreManager.SaveAll()
	local players = Players:GetPlayers()
	local remaining = #players

	if remaining == 0 then
		return true
	end

	local completed = 0

	for _, player in ipairs(players) do
		task.spawn(function()
			DataStoreManager.SavePlayer(player, true)
			completed += 1
		end)
	end

	local startTime = os.clock()

	while completed < remaining and os.clock() - startTime < 25 do
		task.wait(0.1)
	end

	return completed == remaining
end

function DataStoreManager.ReleasePlayer(player)
	return DataStoreManager.SavePlayer(player, true)
end

task.spawn(function()
	while not shuttingDown do
		task.wait(AUTOSAVE_INTERVAL)

		if shuttingDown then
			break
		end

		for _, session in pairs(sessions) do
			if session.Loaded and session.Dirty and not session.Saving then
				task.spawn(function()
					local success, result = saveSession(session, false)

					if not success then
						warn("[DataStoreManager] Autosave failed for " .. session.Player.Name .. ": " .. tostring(result))
					end
				end)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	DataStoreManager.ReleasePlayer(player)
end)

game:BindToClose(function()
	shuttingDown = true

	local players = Players:GetPlayers()

	for _, player in ipairs(players) do
		task.spawn(function()
			DataStoreManager.SavePlayer(player, true)
		end)
	end

	local startTime = os.clock()

	while os.clock() - startTime < 25 do
		local activeSessions = 0

		for _, session in pairs(sessions) do
			if session.Saving then
				activeSessions += 1
			end
		end

		if activeSessions == 0 then
			break
		end

		task.wait(0.1)
	end
end)

return DataStoreManager