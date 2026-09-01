--!nonstrict
--[[
    Main.server.luau
    Server entrypoint initializing all game services with fault-tolerant safeInit protected execution.
    Location: src/server/Main.server.luau (Syncs to ServerScriptService.Server.Main)
--]]

local Services = script.Parent:WaitForChild("Services")

-- Protected Async Initialization Wrapper
local function safeInit(name: string, initFn: () -> ())
	task.spawn(function()
		local success, err = pcall(initFn)
		if not success then
			warn(string.format("❌ [Server Init Error] Service %q failed to initialize: %s", name, tostring(err)))
		end
	end)
end

-- Explicit order of core server services initialization with safeInit protection
local SERVICE_ORDER = {
	"DataStoreManager",
	"StackServer",
	"CoinSpawner",
	"LootExplosion",
	"HitboxService",
	"DummySpawner",
	"BankServer",
	"CombatServer",
	"SettingsService",
	"GuardAIService",
}

for _, serviceName in ipairs(SERVICE_ORDER) do
	local serviceScript = Services:FindFirstChild(serviceName)
	if serviceScript and serviceScript:IsA("ModuleScript") then
		local service = require(serviceScript) :: any
		if typeof(service) == "table" and typeof(service.Init) == "function" then
			safeInit(serviceName, service.Init)
		end
	end
end

print("[ServerMain] All Don't Drop The Coin server services initialized successfully with safeInit protection!")
