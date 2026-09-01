--!strict
--[[
    AttackState.luau
    Universal Roblox AI Workspace Attack State.
    Executes attack lunge / animation and calls onAttackHit callback.
    Location: src/shared/AI/States/AttackState.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local StateMachine = require(Packages:WaitForChild("StateMachineModule"))

local AttackState: StateMachine.StateDefinition = {
	name = "Attack",

	canEnter = function(context: any, fromState: string?): (boolean, string?)
		return true, nil
	end,

	enter = function(context: any, fromState: string?)
		context.isAttacking = true

		task.spawn(function()
			local primaryPart = context.primaryPart
			local targetHrp = context.currentTargetHrp

			if primaryPart and targetHrp and targetHrp.Parent then
				-- Attack Lunge forward towards target
				local attackDir = (targetHrp.Position - primaryPart.Position).Unit
				if context.humanoid then
					context.humanoid:MoveTo(primaryPart.Position + (attackDir * 3))
				end

				-- Invoke Attack Callback (triggers knockback & coin scatter)
				if context.onAttackHit then
					context.onAttackHit(targetHrp.Parent)
				end
			end

			task.wait(context.attackRecoveryTime or 0.5)
			context.isAttacking = false
		end)
	end,

	exit = function(context: any, toState: string?)
	end,

	update = function(context: any): string?
		if not context.isAttacking then
			return "Chase"
		end
		return nil
	end,
}

return AttackState
