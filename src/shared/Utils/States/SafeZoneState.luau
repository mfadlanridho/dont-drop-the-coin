--!nonstrict
--[[
    SafeZoneState.luau
    State definition for Ground Lobby Safe Zone (PvP immune).
    Location: src/shared/Utils/States/SafeZoneState.luau
--]]

local StateMachine = require(script.Parent.Parent:WaitForChild("StateMachine"))

local SafeZoneState: StateMachine.StateDefinition = {
	name = "SafeZone",

	canEnter = function(context, fromState)
		return true, nil
	end,

	enter = function(context, fromState)
		print(string.format("[SafeZoneState] %s entered Ground Lobby Safe Zone.", context.player and context.player.Name or "Unknown"))
	end,

	exit = function(context, toState)
		print(string.format("[SafeZoneState] %s exited Ground Lobby Safe Zone.", context.player and context.player.Name or "Unknown"))
	end,

	update = function(context)
		return nil
	end,
}

return SafeZoneState
