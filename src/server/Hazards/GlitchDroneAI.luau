--!strict
--[[
    GlitchDroneAI.luau
    Modular OOP component for Zone 3 "Glitch Drone" AI Hunter Monsters.
    Patrols Zone 3 sky platforms, targets nearby players within 40 studs, and triggers a knockback ragdoll bump on contact.
    Location: src/server/Hazards/GlitchDroneAI.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)

local log = Logger.create("Combat")

local Services = script.Parent.Parent:WaitForChild("Services")
local CombatServer = require(Services:WaitForChild("CombatServer") :: ModuleScript)

local GlitchDroneAI = {}
GlitchDroneAI.__index = GlitchDroneAI

type DroneInstance = {
	model: Model,
	primaryPart: BasePart,
	startPos: Vector3,
	detectionRadius: number,
	moveSpeed: number,
	isDestroyed: boolean,
	heartbeatConn: RBXScriptConnection?,
	touchConn: RBXScriptConnection?,
}

function GlitchDroneAI.new(model: Model, detectionRadius: number?, moveSpeed: number?): DroneInstance
	local self = setmetatable({}, GlitchDroneAI) :: any
	self.model = model
	self.primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	self.startPos = self.primaryPart and self.primaryPart.Position or Vector3.zero
	self.detectionRadius = detectionRadius or 40
	self.moveSpeed = moveSpeed or 14
	self.isDestroyed = false

	self:init()
	return self
end

function GlitchDroneAI:init()
	if not self.primaryPart then return end
	self.primaryPart.Anchored = true

	-- Touch listener for ragdoll impact
	self.touchConn = self.primaryPart.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			log(string.format("[GlitchDroneAI] Drone %s caught player %s!", self.model.Name, player.Name))
			CombatServer.BumpVictimModel(nil, character)
		end
	end)

	-- Drone AI Movement Loop (Find nearest player within 40 studs or patrol)
	local startTime = os.clock()
	self.heartbeatConn = RunService.Heartbeat:Connect(function()
		if self.isDestroyed or not self.primaryPart or not self.primaryPart.Parent then
			self:destroy()
			return
		end

		local nearestPlayerHrp: BasePart? = nil
		local shortestDist = self.detectionRadius

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local dist = (hrp.Position - self.primaryPart.Position).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					nearestPlayerHrp = hrp
				end
			end
		end

		local targetPos = self.startPos
		if nearestPlayerHrp then
			targetPos = nearestPlayerHrp.Position + Vector3.new(0, 2, 0)
		else
			-- Idle Hover Patrol
			local elapsed = os.clock() - startTime
			targetPos = self.startPos + Vector3.new(math.sin(elapsed * 1.5) * 10, math.cos(elapsed * 2) * 2, 0)
		end

		-- Move towards target position smoothly
		local currentPos = self.primaryPart.Position
		local moveDir = (targetPos - currentPos)
		if moveDir.Magnitude > 0.5 then
			local newPos = currentPos + (moveDir.Unit * math.min(moveDir.Magnitude, self.moveSpeed * (1/60)))
			self.primaryPart.CFrame = CFrame.new(newPos, newPos + moveDir)
		end
	end)
end

function GlitchDroneAI:destroy()
	self.isDestroyed = true
	if self.heartbeatConn then
		self.heartbeatConn:Disconnect()
		self.heartbeatConn = nil
	end
	if self.touchConn then
		self.touchConn:Disconnect()
		self.touchConn = nil
	end
end

return GlitchDroneAI
