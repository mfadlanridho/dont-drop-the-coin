--!nonstrict
--[[
    DataStoreTest.luau
    Lightweight unit test script for DataStoreManager API verification.
    Location: src/server/Tests/DataStoreTest.luau (Syncs to ServerScriptService.Server.Tests.DataStoreTest)
--]]

local DataStoreTest = {}

function DataStoreTest.Run()
	print("==================================================")
	print("[UNIT TEST] Running DataStoreManager Unit Tests...")
	print("==================================================")

	local Services = script.Parent.Parent:WaitForChild("Services")
	local DataStoreManager = require(Services:WaitForChild("DataStoreManager"))

	-- 1. Create Mock Player Instance
	local mockPlayer = {
		Name = "UnitTestPlayer",
		UserId = 999999999,
		IsDescendantOf = function(_, parent)
			return true
		end,
	}

	-- 2. Test Initial Data Access
	local data = DataStoreManager.GetData(mockPlayer)
	if data == nil then
		warn("[TEST FAILED] DataStoreManager.GetData returned nil for mock player!")
		return false
	end
	print(string.format("  ✓ Initial Coins: %d | Initial TotalBanked: %d", data.Coins, data.TotalBanked))

	-- 3. Test Adding Banked Cash (Transaction 1: +100 Coins)
	local success1 = DataStoreManager.AddBankedCash(mockPlayer, 100)
	if not success1 or data.Coins ~= 100 or data.TotalBanked ~= 100 then
		warn(string.format("[TEST FAILED] Transaction 1 failed! Coins: %d, Expected: 100", data.Coins))
		return false
	end
	print("  ✓ Transaction 1 Passed (+100 Coins -> Wallet: 100)")

	-- 4. Test Adding Banked Cash (Transaction 2: +250 Coins)
	local success2 = DataStoreManager.AddBankedCash(mockPlayer, 250)
	if not success2 or data.Coins ~= 350 or data.TotalBanked ~= 350 then
		warn(string.format("[TEST FAILED] Transaction 2 failed! Coins: %d, Expected: 350", data.Coins))
		return false
	end
	print("  ✓ Transaction 2 Passed (+250 Coins -> Wallet: 350)")

	print("==================================================")
	print("🎉 [ALL UNIT TESTS PASSED] DataStoreManager operates cleanly!")
	print("==================================================")
	return true
end

return DataStoreTest
