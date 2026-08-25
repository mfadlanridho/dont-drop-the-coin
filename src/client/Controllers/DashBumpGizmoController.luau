--!nonstrict
--[[
    DashBumpGizmoController.luau
    Renders object-pooled 3D debug gizmos (Spherecast volume, trajectory line, and hit labels) for Dash Bump skills.
    Updates line color, sphere position, and label text when a player hit occurs.
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

local function getRenderer()
	if not renderer then
		renderer = GizmoRenderer.new("DashBumpDebug", {
			lineThickness = 0.28,
			markerSize = 0.6,
			wireSphereTransparency = 0.4,
		})
	end
	return renderer
end

-- Draw 3D Gizmo Visualization for Dash Bump Sweep (No Hit)
function DashBumpGizmoController.DrawDashGizmo(attackerChar: Model)
	if not RunService:IsStudio() or not DebugConfig.DashBump or not DebugConfig.DashBump.ShowGizmos then
		return
	end

	local hrp = attackerChar:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	local r = getRenderer()
	local origin = hrp.Position
	local dashVector = hrp.CFrame.LookVector * Config.DASH_DISTANCE
	local target = origin + dashVector
	local sphereRadius = 4.5

	-- 1. Trajectory Line (Cyan)
	local line = r:getLine("DashTrajectoryLine", Color3.fromRGB(0, 220, 255))
	r:setLine(line, origin, target, Color3.fromRGB(0, 220, 255))

	-- 2. Swept Wire Sphere (Magenta)
	local wireSphere = r:getWireSphere("DashSpherecastVolume", Color3.fromRGB(255, 50, 200), sphereRadius)
	r:setWireSphere(wireSphere, target, sphereRadius, Color3.fromRGB(255, 50, 200))

	-- 3. Point Label (Yellow)
	local labelAnchor = r:getPointLabel("DashLabel", "DASH BUMP SWEEP (15 Studs)", Color3.fromRGB(255, 220, 0))
	r:setPointLabel(labelAnchor, target + Vector3.new(0, 2.5, 0), "DASH BUMP SWEEP (15 Studs)", Color3.fromRGB(255, 220, 0))

	-- Hide after 1.5 seconds
	task.delay(1.5, function()
		if renderer then
			renderer:hideAll()
		end
	end)
end

-- Draw 3D Gizmo Visualization for Dash Bump HIT (Target Impact)
function DashBumpGizmoController.DrawHitGizmo(attackerChar: Model, victimName: string, hitPosition: Vector3, knockbackForce: number)
	if not RunService:IsStudio() or not DebugConfig.DashBump or not DebugConfig.DashBump.ShowGizmos then
		return
	end

	local hrp = attackerChar:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	local r = getRenderer()
	local origin = hrp.Position
	local sphereRadius = 4.5

	-- 1. Trajectory Line to Hit Location (Bright Red)
	local line = r:getLine("DashTrajectoryLine", Color3.fromRGB(255, 50, 50))
	r:setLine(line, origin, hitPosition, Color3.fromRGB(255, 50, 50))

	-- 2. Wire Sphere Stopped at Impact Location (Golden Orange)
	local wireSphere = r:getWireSphere("DashSpherecastVolume", Color3.fromRGB(255, 180, 0), sphereRadius)
	r:setWireSphere(wireSphere, hitPosition, sphereRadius, Color3.fromRGB(255, 180, 0))

	-- 3. Hit Impact Marker (Bright Red Sphere)
	local hitMarker = r:getMarker("DashHitMarker", Color3.fromRGB(255, 30, 30))
	r:setMarker(hitMarker, hitPosition, Color3.fromRGB(255, 30, 30))

	-- 4. Hit Label (Bright Gold)
	local labelText = string.format("BUMP HIT! (%s, Force: %.0f)", victimName, knockbackForce)
	local labelAnchor = r:getPointLabel("DashLabel", labelText, Color3.fromRGB(255, 255, 100))
	r:setPointLabel(labelAnchor, hitPosition + Vector3.new(0, 3.0, 0), labelText, Color3.fromRGB(255, 255, 100))

	-- Keep hit indicator visible for 2.0 seconds
	task.delay(2.0, function()
		if renderer then
			renderer:hideAll()
		end
	end)
end

function DashBumpGizmoController.Init()
	-- Listen for local player dash trigger
	LocalPlayer.AttributeChanged:Connect(function(attr)
		if attr == "FSMState" and LocalPlayer:GetAttribute("FSMState") == "Dashing" then
			if LocalPlayer.Character then
				DashBumpGizmoController.DrawDashGizmo(LocalPlayer.Character)
			end
		end
	end)

	-- Listen for server DashBumpHit event
	local hitEvent = Remotes.Get("DashBumpHit")
	if hitEvent then
		hitEvent.OnClientEvent:Connect(function(attackerPlayer, victimName, hitPosition, knockbackForce)
			local char = attackerPlayer and attackerPlayer.Character or LocalPlayer.Character
			if char then
				DashBumpGizmoController.DrawHitGizmo(char, victimName, hitPosition, knockbackForce)
			end
		end)
	end

	print("[DashBumpGizmoController] Debug Gizmo Renderer initialized.")
end

return DashBumpGizmoController
