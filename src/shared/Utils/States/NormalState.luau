--!nonstrict
--[[
    NormalState.luau
    State definition for default normal walking/climbing gameplay state.
    Location: src/shared/Utils/States/NormalState.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local StateMachine = require(Packages:WaitForChild("StateMachineModule"))

local NormalState: StateMachine.StateDefinition = {
	name = "Normal",

	canEnter = function(context, fromState)
		return true, nil
	end,

	enter = function(context, fromState)
		print(string.format("[NormalState] Entered Normal state for %s", context.player and context.player.Name or "Unknown"))

		-- Ensure normal humanoid steering and platformstand are clean
		local humanoid = context.humanoid
		if humanoid then
			humanoid.AutoRotate = true
			humanoid.PlatformStand = false
		end
	end,

	exit = function(context, toState)
	end,

	update = function(context)
		return nil
	end,
}

return NormalState
