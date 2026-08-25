--!nonstrict
--[[
    DashingState.luau
    State definition for Dash Bump ability execution (0.3s duration).
    Location: src/shared/Utils/States/DashingState.luau
--]]

local StateMachine = require(script.Parent.Parent:WaitForChild("StateMachine"))

local DashingState: StateMachine.StateDefinition = {
	name = "Dashing",

	canEnter = function(context, fromState)
		if fromState == "Ragdolled" then
			return false, "cannot_dash_while_ragdolled"
		end
		if fromState == "SafeZone" then
			return false, "cannot_dash_in_safe_zone"
		end
		return true, nil
	end,

	enter = function(context, fromState)
		print(string.format("[DashingState] %s casting Dash Bump!", context.player and context.player.Name or "Unknown"))
	end,

	exit = function(context, toState)
	end,

	update = function(context)
		return nil
	end,
}

return DashingState
