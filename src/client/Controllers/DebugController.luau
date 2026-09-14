--!nonstrict
--[[
    DebugController.luau
    Clean, minimal, 100% event-driven developer debug controller for FSM State monitoring and Hitbox wireframe toggles.
    Zero loops, zero RenderStepped overhead.
    Location: src/client/Controllers/DebugController.luau (Syncs to StarterPlayerScripts.Client.Controllers.DebugController)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Config = require(Shared:WaitForChild("Config"))

local Remotes = require(Shared:WaitForChild("Remotes"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))
local DebugGuiModule = require(Packages:WaitForChild("DebugGuiModule"))

local Controllers = script.Parent
local DashBumpGizmoController = require(Controllers:WaitForChild("DashBumpGizmoController"))

local LocalPlayer = Players.LocalPlayer
local DebugController = {}

function DebugController.Init()
	print(string.format("[DebugController] 🚀 Initializing DebugController! IsStudio=%s", tostring(RunService:IsStudio())))
	if not RunService:IsStudio() then return end

	-- Initialize Developer Debug Suite ('P' key listener)
	DebugGuiModule.Init()

	-- 1. Register "Player State" Debug Panel Tab (Order 1)
	local playerPanel = DebugGuiModule.registerPanel("Player", "Player State", 1)

	local function updateStateEntry()
		local currentState = PlayerFSM.GetState(LocalPlayer)
		DebugGuiModule.setEntry("Player", "FSMState", "FSM State:", tostring(currentState))
	end

	-- Initial display update
	updateStateEntry()

	-- Action: Reset State to Normal
	DebugGuiModule.setAction("Player", "ResetState", "Reset State to Normal", function()
		PlayerFSM.SetState(LocalPlayer, "Normal")
		updateStateEntry()
	end)

	-- 2. Register "Coins & Encumbrance" Debug Panel Tab (Order 2)
	local coinsPanel = DebugGuiModule.registerPanel("Coins", "Coins & Encumbrance", 2)
	local devStackActionRemote = Remotes.Get("DevStackAction")
	local bankRemote = Remotes.Get("BankCoins")
	local updateStackRemote = Remotes.Get("UpdateStack")

	local function updateCoinEntries(count: number?, weight: number?, coins: { number }?)
		local stackCount = count or 0
		local totalWeight = weight or 0
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local currentSpeed = humanoid and humanoid.WalkSpeed or 16
		local speedPct = math.round((currentSpeed / 16) * 100)

		local estCash = 0
		if coins and #coins > 0 then
			for _, tier in ipairs(coins) do
				local tData = Config.ZONE_TIERS and Config.ZONE_TIERS[tier]
				estCash += (tData and tData.Multiplier) or 1.0
			end
		else
			estCash = stackCount
		end

		DebugGuiModule.setEntry("Coins", "StackCount", "Stack Count:", string.format("%d coins", stackCount))
		DebugGuiModule.setEntry("Coins", "TotalWeight", "Stack Weight:", string.format("%.1f units", totalWeight))
		DebugGuiModule.setEntry("Coins", "WalkSpeed", "WalkSpeed:", string.format("%.1f studs/s (%d%%)", currentSpeed, speedPct))
		DebugGuiModule.setEntry("Coins", "EstValue", "Estimated Cash:", string.format("$%.2f", estCash))
	end

	-- Initial display
	updateCoinEntries(0, 0, {})

	-- Actions for Coins tab
	DebugGuiModule.setAction("Coins", "AddT1", "+5 Tier 1 Coins (Bronze)", function()
		if devStackActionRemote then devStackActionRemote:FireServer("AddCoins", 1, 5) end
	end, 1)

	DebugGuiModule.setAction("Coins", "AddT5", "+5 Tier 5 Coins (Sapphire)", function()
		if devStackActionRemote then devStackActionRemote:FireServer("AddCoins", 5, 5) end
	end, 2)

	DebugGuiModule.setAction("Coins", "AddT10", "+5 Tier 10 Coins (Celestial)", function()
		if devStackActionRemote then devStackActionRemote:FireServer("AddCoins", 10, 5) end
	end, 3)

	DebugGuiModule.setAction("Coins", "HitMaxWeight", "Hit Max Weight (Cap at 8 studs/s)", function()
		if devStackActionRemote then devStackActionRemote:FireServer("HitMaxWeight") end
	end, 4)

	DebugGuiModule.setAction("Coins", "LootExplosion", "Trigger Loot Explosion", function()
		if devStackActionRemote then devStackActionRemote:FireServer("LootExplosion") end
	end, 5)

	DebugGuiModule.setAction("Coins", "BankStack", "Bank Current Stack", function()
		if bankRemote then bankRemote:FireServer() end
	end, 6)

	DebugGuiModule.setAction("Coins", "ClearStack", "Clear Stack (Reset)", function()
		if devStackActionRemote then devStackActionRemote:FireServer("ClearStack") end
	end, 7)

	-- Event listeners for dynamic coin status updates
	if updateStackRemote then
		updateStackRemote.OnClientEvent:Connect(function(targetPlayer, newCount, totalWeight, coinsList)
			if targetPlayer == LocalPlayer then
				task.defer(function()
					updateCoinEntries(newCount, totalWeight, coinsList)
				end)
			end
		end)
	end

	local function bindSpeedListener(char: Model)
		local humanoid = char:WaitForChild("Humanoid") :: Humanoid?
		if humanoid then
			humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				local currentSpeed = humanoid.WalkSpeed
				local speedPct = math.round((currentSpeed / 16) * 100)
				DebugGuiModule.setEntry("Coins", "WalkSpeed", "WalkSpeed:", string.format("%.1f studs/s (%d%%)", currentSpeed, speedPct))
			end)
		end
	end

	LocalPlayer.CharacterAdded:Connect(bindSpeedListener)
	if LocalPlayer.Character then
		bindSpeedListener(LocalPlayer.Character)
	end

	-- 3. Register "Combat & Hitboxes" Debug Panel Tab (Order 3)
	local combatPanel = DebugGuiModule.registerPanel("Combat", "Combat & Hitboxes", 3)
	DebugGuiModule.setEntry("Combat", "HitboxStatus", "3D Hitbox Wireframes:", "HIDDEN")

	-- Action: Toggle 3D Hitbox Wireframes
	DebugGuiModule.setAction("Combat", "ToggleHitboxes", "Toggle 3D Hitbox Wireframes", function()
		local cfg = DashBumpGizmoController.DebugConfig.DashBump
		cfg.AlwaysShowHitboxes = not cfg.AlwaysShowHitboxes
		DebugGuiModule.setEntry("Combat", "HitboxStatus", "3D Hitbox Wireframes:", cfg.AlwaysShowHitboxes and "VISIBLE" or "HIDDEN")
	end)

	-- 4. Register "Map Teleport" Debug Panel Tab (Order 4)
	local teleportPanel = DebugGuiModule.registerPanel("Teleport", "Map Teleport", 4)
	local devTeleportRemote = Remotes.Get("DevTeleport")

	local function requestTeleport(destKey: string)
		if devTeleportRemote then
			devTeleportRemote:FireServer(destKey)
		end
	end

	-- Base Floor
	DebugGuiModule.setAction("Teleport", "00_BaseFloor", "Base Floor", function()
		requestTeleport("BaseFloor")
	end, 1)

	-- Zones 1 through 10
	local ZONE_DEFS = {
		{ num = 1, name = "Sunny Start" },
		{ num = 2, name = "Chaos Factory" },
		{ num = 3, name = "Void Lunatic" },
		{ num = 4, name = "Mechanical Works" },
		{ num = 5, name = "Neon City" },
		{ num = 6, name = "Aquatica" },
		{ num = 7, name = "Temple Of Ascension" },
		{ num = 8, name = "Sky Kingdom" },
		{ num = 9, name = "Mystic Realm" },
		{ num = 10, name = "Hellfire" },
	}

	for _, zone in ipairs(ZONE_DEFS) do
		local orderNum = zone.num + 1
		local actionKey = string.format("%02d_Zone%d", zone.num, zone.num)
		local label = string.format("Zone %d: %s", zone.num, zone.name)
		DebugGuiModule.setAction("Teleport", actionKey, label, function()
			requestTeleport(string.format("Zone%d", zone.num))
		end, orderNum)
	end

	-- Spawn / Greybox (0, 0)
	DebugGuiModule.setAction("Teleport", "99_Spawn", "Spawn / Greybox (0, 0)", function()
		requestTeleport("Spawn")
	end, 99)

	-- 100% EVENT-DRIVEN: Listen to unified PlayerFSM state transition events
	PlayerFSM.OnStateChanged(LocalPlayer, function(oldState, newState)
		updateStateEntry()
	end)

	print("[DebugController] Minimal 100% event-driven FSM, Coins, Hitbox & Teleport Debug Controller initialized successfully!")
end

return DebugController
