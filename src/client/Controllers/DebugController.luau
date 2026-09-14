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

	-- 2. Register "Combat & Hitboxes" Debug Panel Tab (Order 2)
	local combatPanel = DebugGuiModule.registerPanel("Combat", "Combat & Hitboxes", 2)
	DebugGuiModule.setEntry("Combat", "HitboxStatus", "3D Hitbox Wireframes:", "HIDDEN")

	-- Action: Toggle 3D Hitbox Wireframes
	DebugGuiModule.setAction("Combat", "ToggleHitboxes", "Toggle 3D Hitbox Wireframes", function()
		local cfg = DashBumpGizmoController.DebugConfig.DashBump
		cfg.AlwaysShowHitboxes = not cfg.AlwaysShowHitboxes
		DebugGuiModule.setEntry("Combat", "HitboxStatus", "3D Hitbox Wireframes:", cfg.AlwaysShowHitboxes and "VISIBLE" or "HIDDEN")
	end)

	-- 3. Register "Map Teleport" Debug Panel Tab (Order 3)
	local teleportPanel = DebugGuiModule.registerPanel("Teleport", "Map Teleport", 3)
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

	print("[DebugController] Minimal 100% event-driven FSM, Hitbox & Teleport Debug Controller initialized successfully!")
end

return DebugController
