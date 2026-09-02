--!nonstrict
--[[
    RagdollState.luau
    State definition for physics ragdoll & loot explosion state (2.5s duration).
    Location: src/shared/Utils/States/RagdollState.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local StateMachine = require(Packages:WaitForChild("StateMachineModule"))
local RagdollModule = require(Packages:WaitForChild("RagdollModule") :: ModuleScript)

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

		local payload = context.payload
		local launchVector = payload and payload.launchVector

		local char = context.character or (context.player and context.player.Character)
		if char then
			-- Apply optional physical knockback impulse vector
			if launchVector then
				local hrp = context.rootPart or char:FindFirstChild("HumanoidRootPart") :: BasePart
				if hrp then
					hrp.AssemblyLinearVelocity = launchVector
				end
			end

			-- Enable physics ragdoll platform stand disabler
			RagdollModule.SetPlatformStand(char, true, true)
		end

		-- Physics enabled on enter; server attribute timer automatically resets state to Normal after duration
	end,

	exit = function(context, toState)
		print(string.format("[RagdollState] %s recovering from Ragdoll state.", context.player and context.player.Name or "Unknown"))

		-- Restore humanoid to normal standing state & re-enable animations
		local char = context.character or (context.player and context.player.Character)
		if char and char.Parent then
			RagdollModule.SetPlatformStand(char, false, false)
		end
	end,

	update = function(context)
		return nil
	end,
}

return RagdollState
