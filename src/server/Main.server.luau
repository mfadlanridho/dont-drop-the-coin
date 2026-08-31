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
local LootExplosion = require(Services:WaitForChild("LootExplosion"))
local HitboxService = require(Services:WaitForChild("HitboxService"))
local DummySpawner = require(Services:WaitForChild("DummySpawner"))
local BankServer = require(Services:WaitForChild("BankServer"))
local CombatServer = require(Services:WaitForChild("CombatServer"))
local SettingsService = require(Services:WaitForChild("SettingsService"))
local GuardAIService = require(Services:WaitForChild("GuardAIService"))

DataStoreManager.Init()
StackServer.Init()
CoinSpawner.Init()
LootExplosion.Init()
HitboxService.Init()
DummySpawner.Init()
BankServer.Init()
CombatServer.Init()
SettingsService.Init()
GuardAIService.Init()

print("[ServerMain] All Don't Drop The Coin server services initialized successfully!")
