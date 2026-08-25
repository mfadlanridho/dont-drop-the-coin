--!nonstrict
--[[
    Main.server.luau
    Server entrypoint initializing all game services.
    Location: src/server/Main.server.luau (Syncs to ServerScriptService.Server.Main)
--]]

local Services = script.Parent:WaitForChild("Services")
local DataStoreManager = require(Services:WaitForChild("DataStoreManager"))
local StackServer = require(Services:WaitForChild("StackServer"))
local CoinSpawner = require(Services:WaitForChild("CoinSpawner"))
local CombatServer = require(Services:WaitForChild("CombatServer"))
local LootExplosion = require(Services:WaitForChild("LootExplosion"))

DataStoreManager.Init()
StackServer.Init()
CoinSpawner.Init()
LootExplosion.Init()
CombatServer.Init()

print("[ServerMain] All Don't Drop The Coin server services initialized successfully!")
