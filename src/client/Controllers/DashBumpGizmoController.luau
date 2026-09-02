--!nonstrict
--[[
    DashBumpGizmoController.luau
    Renders object-pooled 3D debug gizmos (Spherecast volume, HitboxCapsule wireframe box, trajectory line, and hit labels) for Dash Bump skills.
    Supports continuous real-time rendering of HitboxCapsule 3D wireframe boxes when AlwaysShowHitboxes is enabled.
    Location: src/client/Controllers/DashBumpGizmoController.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Packages = ReplicatedStorage:WaitForChild("Packages")

local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))
local DebugGuiModule = require(Packages:WaitForChild("DebugGuiModule"))
local GizmoRenderer = DebugGuiModule.GizmoRenderer

local DebugConfig = {
	DashBump = {
		ShowGizmos = RunService:IsStudio(),
		AlwaysShowHitboxes = false,
	}
}

local LocalPlayer = Players.LocalPlayer
local renderer: any
local persistentRenderer: any

local DashBumpGizmoController = {}
DashBumpGizmoController.DebugConfig = DebugConfig

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

local function getPersistentRenderer()
	if not persistentRenderer then
		persistentRenderer = GizmoRenderer.new("PersistentHitboxDebug", {
			lineThickness = 0.2,
		})
	end
	return persistentRenderer
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

	-- 3. Draw Green Wireframe Bounding Box around target HitboxCapsules of other players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= LocalPlayer and otherPlayer.Character then
			local hitbox = otherPlayer.Character:FindFirstChild("HitboxCapsule") :: Part
			if hitbox then
				local wireBox = r:getWireBox("HitboxGizmo_" .. otherPlayer.Name, Color3.fromRGB(0, 255, 120), hitbox.Size)
				r:setWireBox(wireBox, hitbox.CFrame, hitbox.Size, Color3.fromRGB(0, 255, 120))
			end
		end
	end

	-- 4. Point Label (Yellow)
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

	-- 4. Draw Red Wireframe Box around Victim's HitboxCapsule
	local victimPlayer = Players:FindFirstChild(victimName) :: Player?
	if victimPlayer and victimPlayer.Character then
		local hitbox = victimPlayer.Character:FindFirstChild("HitboxCapsule") :: Part
		if hitbox then
			local wireBox = r:getWireBox("HitboxGizmo_" .. victimName, Color3.fromRGB(255, 40, 40), hitbox.Size)
			r:setWireBox(wireBox, hitbox.CFrame, hitbox.Size, Color3.fromRGB(255, 40, 40))
		end
	end

	-- 5. Hit Label (Bright Gold)
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
	-- Listen for local player dash trigger via unified PlayerFSM event
	PlayerFSM.OnStateChanged(LocalPlayer, function(oldState, newState)
		if newState == "Dashing" and LocalPlayer.Character then
			DashBumpGizmoController.DrawDashGizmo(LocalPlayer.Character)
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

	-- Continuous RenderStepped loop for Always-On Hitbox Wireframes
	RunService.RenderStepped:Connect(function()
		if not RunService:IsStudio() then return end

		local pr = getPersistentRenderer()
		if not DebugConfig.DashBump or not DebugConfig.DashBump.AlwaysShowHitboxes then
			pr:hideAll()
			return
		end

		-- Render continuous Green 3D Wireframe Box around all HitboxCapsules in Workspace
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("Part") and descendant.Name == "HitboxCapsule" then
				local model = descendant.Parent
				local modelName = model and model.Name or "Unknown"
				local wireBox = pr:getWireBox("AlwaysOnHitbox_" .. descendant:GetFullName(), Color3.fromRGB(0, 255, 120), descendant.Size)
				pr:setWireBox(wireBox, descendant.CFrame, descendant.Size, Color3.fromRGB(0, 255, 120))
			end
		end
	end)

	print("[DashBumpGizmoController] Debug Gizmo Renderer initialized with continuous Hitbox visualizer support.")
end

return DashBumpGizmoController
