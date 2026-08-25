--!nonstrict
--[[
    RagdollState.luau
    State definition for physics ragdoll & loot explosion state (2.5s duration).
    Location: src/shared/Utils/States/RagdollState.luau
--]]

local StateMachine = require(script.Parent.Parent:WaitForChild("StateMachine"))

local RagdollState: StateMachine.StateDefinition = {
	name = "Ragdolled",

	canEnter = function(context, fromState)
		if fromState == "SafeZone" then
			return false, "immune_in_safe_zone"
		end
		return true, nil
	end,

	enter = function(context, fromState)
		print(string.format("[RagdollState] %s forced into Ragdoll state!", context.player and context.player.Name or "Unknown"))
	end,

	exit = function(context, toState)
		print(string.format("[RagdollState] %s recovering from Ragdoll state.", context.player and context.player.Name or "Unknown"))
	end,

	update = function(context)
		return nil
	end,
}

return RagdollState
