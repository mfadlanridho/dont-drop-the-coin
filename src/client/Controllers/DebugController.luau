--!nonstrict
--[[
    DebugController.luau
    Dedicated client controller managing developer debug tabs, live player metrics, real-time FSM monitoring, and interactive test actions.
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

	print("[DebugController] 🛠️ Registering Debug Panels (Player, Combat, Economy)...")
	-- 1. Register "Player State & Physics" Panel Tab (Order 1)
	local playerPanel = DebugGuiModule.registerPanel("Player", "Player State & Physics", 1)
	DebugGuiModule.setEntry("Player", "FSMState", "Player State:", "Normal")
	DebugGuiModule.setEntry("Player", "Speed", "Movement Speed:", "0.0 studs/s")
	DebugGuiModule.setEntry("Player", "Health", "Humanoid Health:", "100 / 100")

	-- Action: Reset State to Normal
	DebugGuiModule.setAction("Player", "ResetState", "Reset FSM State to Normal", function()
		PlayerFSM.SetState(LocalPlayer, "Normal")
		DebugGuiModule.setEntry("Player", "FSMState", "Player State:", "Normal (Reset)")
	end)

	-- 2. Register "Combat & Visuals" Panel Tab (Order 2)
	local combatPanel = DebugGuiModule.registerPanel("Combat", "Combat & Gizmos", 2)
	DebugGuiModule.setEntry("Combat", "HitboxStatus", "Hitbox Wireframes:", "HIDDEN")

	-- Action: Toggle 3D Hitbox Wireframes
	DebugGuiModule.setAction("Combat", "ToggleHitboxes", "Toggle Always-On Hitbox Wireframes", function()
		local cfg = DashBumpGizmoController.DebugConfig.DashBump
		cfg.AlwaysShowHitboxes = not cfg.AlwaysShowHitboxes
		DebugGuiModule.setEntry("Combat", "HitboxStatus", "Hitbox Wireframes:", cfg.AlwaysShowHitboxes and "VISIBLE" or "HIDDEN")
	end)

	-- -- 3. Register "Economy & Stack" Panel Tab (Order 3)
	-- local economyPanel = DebugGuiModule.registerPanel("Economy", "Economy & Stack", 3)
	-- DebugGuiModule.setEntry("Economy", "StackCount", "Head Stack Count:", "0 coins")
	-- DebugGuiModule.setEntry("Economy", "Coins", "Banked Coins:", "$0")

	-- -- Real-time RenderStepped metric update loop
	-- RunService.RenderStepped:Connect(function()
	-- 	local char = LocalPlayer.Character
	-- 	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: Part?
	-- 	local humanoid = char and char:FindFirstChildOfClass("Humanoid") :: Humanoid?

	-- 	-- Live FSM state update
	-- 	local currentState = PlayerFSM.GetState(LocalPlayer)
	-- 	DebugGuiModule.setEntry("Player", "FSMState", "Player State:", tostring(currentState))

	-- 	-- Live speed update
	-- 	local speed = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
	-- 	DebugGuiModule.setEntry("Player", "Speed", "Movement Speed:", string.format("%.1f studs/s", speed))

	-- 	-- Live health update
	-- 	if humanoid then
	-- 		DebugGuiModule.setEntry("Player", "Health", "Humanoid Health:", string.format("%.0f / %.0f", humanoid.Health, humanoid.MaxHealth))
	-- 	end

	-- 	-- Live leaderstats update
	-- 	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	-- 	if leaderstats then
	-- 		local stackVal = leaderstats:FindFirstChild("Stack") :: IntValue?
	-- 		local coinsVal = leaderstats:FindFirstChild("Coins") :: IntValue?
	-- 		if stackVal then
	-- 			DebugGuiModule.setEntry("Economy", "StackCount", "Head Stack Count:", string.format("%d coins", stackVal.Value))
	-- 		end
	-- 		if coinsVal then
	-- 			DebugGuiModule.setEntry("Economy", "Coins", "Banked Coins:", string.format("$%d", coinsVal.Value))
	-- 		end
	-- 	end
	-- end)

	print("[DebugController] Dedicated Developer Debug Controller initialized successfully!")
end

return DebugController
