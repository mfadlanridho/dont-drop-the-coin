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

	-- 100% EVENT-DRIVEN: Listen to unified PlayerFSM state transition events
	PlayerFSM.OnStateChanged(LocalPlayer, function(oldState, newState)
		updateStateEntry()
	end)

	print("[DebugController] Minimal 100% event-driven FSM State & Hitbox Debug Controller initialized successfully!")
end

return DebugController
