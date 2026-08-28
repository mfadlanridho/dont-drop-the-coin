--!strict
--[[
    GlitchDroneAI.luau
    Wrapper for Zone 3 Glitch Drones using the generic reusable GuardAI class.
    Location: src/server/Hazards/GlitchDroneAI.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Services = script.Parent.Parent:WaitForChild("Services")
local CombatServer = require(Services:WaitForChild("CombatServer") :: ModuleScript)

local ServerFolder = script.Parent.Parent
local GuardAI = require(ServerFolder:WaitForChild("NPCAI"):WaitForChild("GuardAI") :: ModuleScript)

local GlitchDroneAI = {}
GlitchDroneAI.__index = GlitchDroneAI

function GlitchDroneAI.new(model: Model, detectionRadius: number?, moveSpeed: number?): any
	return GuardAI.new(model, {
		detectionRadius = detectionRadius or 40,
		moveSpeed = moveSpeed or 16,
		attackRadius = 5.0,
		onAttackHit = function(victimModel: Model)
			CombatServer.BumpVictimModel(nil, victimModel)
		end,
	})
end

return GlitchDroneAI
