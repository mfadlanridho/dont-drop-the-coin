local RunService = game:GetService("RunService")

local ResetService = {}

local function buildFreshData(config)
	local freshData = config.deepCopy(config.defaultData)
	freshData.Nonesaveable = config.deepCopy(config.defaultNonesaveable)
	freshData.Tools = {}
	freshData.Index = {}
	return freshData
end

local function removePersistentKey(playerDataStore, key, saveRetries, retryDelay)
	local lastError = nil
	for _ = 1, saveRetries do
		local ok, err = pcall(function()
			playerDataStore:RemoveAsync(key)
		end)
		if ok then
			return true, nil
		end

		lastError = err
		task.wait(retryDelay)
	end

	return false, lastError
end

function ResetService.create(config)
	local service = {}

	function service.resetPlayerData(player)
		if not RunService:IsStudio() then
			return false, "studioOnly"
		end

		if player == nil or player.Parent == nil then
			return false, "invalidPlayer"
		end

		local key = "Player_" .. player.UserId
		local state = config.playerState[player.UserId]
		local previousLoaded = state and state.loaded or nil
		local previousSaving = state and state.saving or nil
		local previousData = state and config.deepCopy(state.data) or nil
		if state ~= nil then
			state.loaded = false
			state.saving = false
			state.data = buildFreshData(config)
		else
			state = config.newState()
			state.data = buildFreshData(config)
			config.playerState[player.UserId] = state
		end

		-- Cash loop cleanup is handled by SlotPlacement's PlayerRemoving handler
		-- when the player is kicked below.

		local success, removeError = removePersistentKey(
			config.playerDataStore,
			key,
			config.saveRetries,
			config.retryDelay
		)

		if not success then
			state.loaded = previousLoaded
			state.saving = previousSaving
			state.data = previousData
			warn(string.format(
				"[DataManager][Reset][WARN] player=%s userId=%d key=%s failed=%s",
				player.Name,
				player.UserId,
				key,
				tostring(removeError)
			))
			return false, removeError
		end

		print(string.format(
			"[DataManager][Reset][OK] player=%s userId=%d key=%s action=RemoveAsync+Kick",
			player.Name,
			player.UserId,
			key
		))

		player:Kick("Studio data reset. Rejoin to load fresh defaults.")
		return true
	end

	return service
end

return ResetService
