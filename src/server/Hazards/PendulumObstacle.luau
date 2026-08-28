--!strict
--[[
    PendulumObstacle.luau
    Modular OOP component for Zone 2 swinging Pendulum obstacles.
    Oscillates back and forth across walkways using sine-wave interpolation. Triggers knockback launch and ragdoll bump on contact.
    Location: src/server/Hazards/PendulumObstacle.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)

local log = Logger.create("Combat")

local Services = script.Parent.Parent:WaitForChild("Services")
local CombatServer = require(Services:WaitForChild("CombatServer") :: ModuleScript)

local PendulumObstacle = {}
PendulumObstacle.__index = PendulumObstacle

type PendulumInstance = {
	part: BasePart,
	pivotCFrame: CFrame,
	swingAngle: number,
	swingSpeed: number,
	isDestroyed: boolean,
	heartbeatConn: RBXScriptConnection?,
	touchConn: RBXScriptConnection?,
}

function PendulumObstacle.new(part: BasePart, swingAngle: number?, swingSpeed: number?): PendulumInstance
	local self = setmetatable({}, PendulumObstacle) :: any
	self.part = part
	self.pivotCFrame = part.CFrame
	self.swingAngle = math.rad(swingAngle or 45)
	self.swingSpeed = swingSpeed or 2.5
	self.isDestroyed = false

	self:init()
	return self
end

function PendulumObstacle:init()
	self.part.Anchored = true

	-- Touch listener for ragdoll impact
	self.touchConn = self.part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			log(string.format("[PendulumObstacle] Player %s struck by pendulum %s!", player.Name, self.part.Name))
			CombatServer.BumpVictimModel(nil, character)
		end
	end)

	-- Sine Wave Swing Animation
	local startTime = os.clock()
	self.heartbeatConn = RunService.Heartbeat:Connect(function()
		if self.isDestroyed or not self.part or not self.part.Parent then
			self:destroy()
			return
		end

		local elapsed = os.clock() - startTime
		local currentRotation = math.sin(elapsed * self.swingSpeed) * self.swingAngle
		self.part.CFrame = self.pivotCFrame * CFrame.Angles(0, 0, currentRotation)
	end)
end

function PendulumObstacle:destroy()
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

return PendulumObstacle
