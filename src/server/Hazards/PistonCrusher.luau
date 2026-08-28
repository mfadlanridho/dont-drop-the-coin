--!strict
--[[
    PistonCrusher.luau
    Modular OOP component for Zone 2 mechanical Piston Crushers.
    Periodically slams down and retracts via TweenService. Triggers knockback, 2.5s ragdoll, and stack explosion on contact.
    Location: src/server/Hazards/PistonCrusher.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)

local log = Logger.create("Combat")

local Services = script.Parent.Parent:WaitForChild("Services")
local CombatServer = require(Services:WaitForChild("CombatServer") :: ModuleScript)

local PistonCrusher = {}
PistonCrusher.__index = PistonCrusher

type PistonCrusherInstance = {
	part: BasePart,
	startPos: Vector3,
	dropDistance: number,
	cycleTime: number,
	isDestroyed: boolean,
	touchConnection: RBXScriptConnection?,
}

function PistonCrusher.new(part: BasePart, dropDistance: number?, cycleTime: number?): PistonCrusherInstance
	local self = setmetatable({}, PistonCrusher) :: any
	self.part = part
	self.startPos = part.Position
	self.dropDistance = dropDistance or 12
	self.cycleTime = cycleTime or 3.0
	self.isDestroyed = false

	self:init()
	return self
end

function PistonCrusher:init()
	self.part.Anchored = true

	-- Touch detection for players
	self.touchConnection = self.part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			log(string.format("[PistonCrusher] Player %s struck by piston %s!", player.Name, self.part.Name))
			CombatServer.BumpVictimModel(nil, character)
		end
	end)

	-- Loop Piston Movement
	task.spawn(function()
		local downPos = self.startPos - Vector3.new(0, self.dropDistance, 0)

		while not self.isDestroyed and self.part and self.part.Parent do
			-- Delay at top
			task.wait(self.cycleTime * 0.5)
			if self.isDestroyed then break end

			-- Fast Slam Down
			local slamTween = TweenService:Create(
				self.part,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = downPos }
			)
			slamTween:Play()
			slamTween.Completed:Wait()

			task.wait(0.3)
			if self.isDestroyed then break end

			-- Smooth Retract Up
			local retractTween = TweenService:Create(
				self.part,
				TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = self.startPos }
			)
			retractTween:Play()
			retractTween.Completed:Wait()
		end
	end)
end

function PistonCrusher:destroy()
	self.isDestroyed = true
	if self.touchConnection then
		self.touchConnection:Disconnect()
		self.touchConnection = nil
	end
end

return PistonCrusher
