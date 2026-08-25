--!nonstrict
--[[
    DashBumpGizmoController.luau
    Renders object-pooled 3D debug gizmos (Spherecast volume, trajectory line, and hit labels) for Dash Bump skills.
    Location: src/client/Controllers/DashBumpGizmoController.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DebugFolder = script.Parent.Parent:WaitForChild("Debug")
local DebugConfig = require(DebugFolder:WaitForChild("DebugConfig"))
local GizmoRenderer = require(DebugFolder:WaitForChild("GizmoRenderer"))

local LocalPlayer = Players.LocalPlayer
local renderer: any

local DashBumpGizmoController = {}

-- Draw 3D Gizmo Visualization for Dash Bump
function DashBumpGizmoController.DrawDashGizmo(attackerChar: Model)
	if not RunService:IsStudio() or not DebugConfig.DashBump or not DebugConfig.DashBump.ShowGizmos then
		return
	end

	local hrp = attackerChar:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	if not renderer then
		renderer = GizmoRenderer.new("DashBumpDebug", {
			lineThickness = 0.25,
			markerSize = 0.5,
			wireSphereTransparency = 0.5,
		})
	end

	local origin = hrp.Position
	local dashVector = hrp.CFrame.LookVector * Config.DASH_DISTANCE
	local target = origin + dashVector
	local sphereRadius = 4.5

	-- 1. Draw Trajectory Line Part (Cyan)
	local line = renderer:getLine("DashTrajectoryLine", Color3.fromRGB(0, 220, 255))
	renderer:setLine(line, origin, target, Color3.fromRGB(0, 220, 255))

	-- 2. Draw Swept Wire Sphere (Magenta)
	local wireSphere = renderer:getWireSphere("DashSpherecastVolume", Color3.fromRGB(255, 50, 200), sphereRadius)
	renderer:setWireSphere(wireSphere, target, sphereRadius, Color3.fromRGB(255, 50, 200))

	-- 3. Draw Point Label (Yellow)
	local labelAnchor = renderer:getPointLabel("DashLabel", "DASH BUMP SWEEP (15 Studs)", Color3.fromRGB(255, 220, 0))
	renderer:setPointLabel(labelAnchor, target + Vector3.new(0, 2.5, 0), "DASH BUMP SWEEP (15 Studs)", Color3.fromRGB(255, 220, 0))

	-- Hide after 1.5 seconds
	task.delay(1.5, function()
		if renderer then
			renderer:hideAll()
		end
	end)
end

function DashBumpGizmoController.Init()
	-- Listen for local player dash event
	local bumpEvent = Remotes.Get("DashBump")
	if bumpEvent then
		bumpEvent.OnClientEvent:Connect(function(attackerPlayer)
			local char = attackerPlayer and attackerPlayer.Character or LocalPlayer.Character
			if char then
				DashBumpGizmoController.DrawDashGizmo(char)
			end
		end)
	end

	-- Also connect to local dash trigger
	LocalPlayer.AttributeChanged:Connect(function(attr)
		if attr == "FSMState" and LocalPlayer:GetAttribute("FSMState") == "Dashing" then
			if LocalPlayer.Character then
				DashBumpGizmoController.DrawDashGizmo(LocalPlayer.Character)
			end
		end
	end)

	print("[DashBumpGizmoController] Debug Gizmo Renderer initialized.")
end

return DashBumpGizmoController
