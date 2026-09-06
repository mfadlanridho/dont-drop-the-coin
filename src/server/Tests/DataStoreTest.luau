--!nonstrict

local DataStoreTest = {}

function DataStoreTest.Run()
	print("==================================================")
	print("[UNIT TEST] Running DataStoreManager Unit Tests...")
	print("==================================================")

	local Services = script.Parent.Parent:WaitForChild("Services")
	local DataStoreManager = require(Services:WaitForChild("DataStoreManager"))

	local mockPlayer = {
		Name = "UnitTestPlayer",
		UserId = 999999999,
	}

	local loadSuccess, loadResult = DataStoreManager.LoadPlayer(mockPlayer)

	if not loadSuccess then
		warn("[TEST FAILED] Failed to load mock player: " .. tostring(loadResult))
		return false
	end

	print("  ✓ Player loaded successfully")

	if not DataStoreManager.IsLoaded(mockPlayer) then
		warn("[TEST FAILED] Player session is not marked as loaded!")
		return false
	end

	print("  ✓ Session ownership established")

	local data = DataStoreManager.GetData(mockPlayer)

	if not data then
		warn("[TEST FAILED] GetData returned nil!")
		return false
	end

	if type(data.Coins) ~= "number" then
		warn("[TEST FAILED] Coins is not a number!")
		return false
	end

	if type(data.TotalBanked) ~= "number" then
		warn("[TEST FAILED] TotalBanked is not a number!")
		return false
	end

	if type(data.DataVersion) ~= "number" then
		warn("[TEST FAILED] DataVersion is missing!")
		return false
	end

	print(string.format(
		"  ✓ Schema valid | Version: %d | Coins: %d | TotalBanked: %d",
		data.DataVersion,
		data.Coins,
		data.TotalBanked
		))

	DataStoreManager.SetCoins(mockPlayer, 0)

	local success1 = DataStoreManager.AddBankedCash(mockPlayer, 100)

	if not success1 then
		warn("[TEST FAILED] Transaction 1 was rejected!")
		return false
	end

	if data.Coins ~= 100 or data.TotalBanked ~= 100 then
		warn(string.format(
			"[TEST FAILED] Transaction 1 incorrect! Coins: %d | TotalBanked: %d",
			data.Coins,
			data.TotalBanked
			))
		return false
	end

	print("  ✓ Transaction 1 passed (+100)")

	local success2 = DataStoreManager.AddBankedCash(mockPlayer, 250)

	if not success2 then
		warn("[TEST FAILED] Transaction 2 was rejected!")
		return false
	end

	if data.Coins ~= 350 or data.TotalBanked ~= 350 then
		warn(string.format(
			"[TEST FAILED] Transaction 2 incorrect! Coins: %d | TotalBanked: %d",
			data.Coins,
			data.TotalBanked
			))
		return false
	end

	print("  ✓ Transaction 2 passed (+250)")

	local negativeTransaction = DataStoreManager.AddBankedCash(mockPlayer, -100)

	if negativeTransaction then
		warn("[TEST FAILED] Negative transaction was accepted!")
		return false
	end

	print("  ✓ Negative transaction rejected")

	local invalidTransaction = DataStoreManager.AddBankedCash(mockPlayer, "100")

	if invalidTransaction then
		warn("[TEST FAILED] Invalid transaction type was accepted!")
		return false
	end

	print("  ✓ Invalid transaction type rejected")

	local removeSuccess = DataStoreManager.RemoveCoins(mockPlayer, 50)

	if not removeSuccess or data.Coins ~= 300 then
		warn("[TEST FAILED] Coin removal failed!")
		return false
	end

	print("  ✓ Coin removal passed (-50)")

	local excessiveRemoval = DataStoreManager.RemoveCoins(mockPlayer, 999999)

	if excessiveRemoval then
		warn("[TEST FAILED] Excessive coin removal was accepted!")
		return false
	end

	print("  ✓ Excessive coin removal rejected")

	local markDirtySuccess = DataStoreManager.MarkDirty(mockPlayer)

	if not markDirtySuccess then
		warn("[TEST FAILED] MarkDirty failed!")
		return false
	end

	print("  ✓ Dirty state tracking passed")

	print(string.format(
		"  ✓ Final State | Coins: %d | TotalBanked: %d",
		data.Coins,
		data.TotalBanked
		))

	local saveSuccess, saveResult = DataStoreManager.SavePlayer(mockPlayer, true)

	if not saveSuccess then
		warn("[TEST FAILED] Save failed: " .. tostring(saveResult))
		return false
	end

	print("  ✓ Save completed successfully")

	if DataStoreManager.IsLoaded(mockPlayer) then
		warn("[TEST FAILED] Session was not released after save!")
		return false
	end

	print("  ✓ Session released")

	print("==================================================")
	print("🎉 [ALL UNIT TESTS PASSED]")
	print("==================================================")

	return true
end

return DataStoreTest