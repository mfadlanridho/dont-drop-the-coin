--!strict
--[[
    AttackState.luau
    Universal Roblox AI Workspace Attack State.
    Executes attack lunge / animation and calls onAttackHit callback.
    Location: src/shared/AI/States/AttackState.luau
--]]

local AttackState = {}
AttackState.name = "Attack"

function AttackState.canEnter(context: any, fromState: string?): (boolean, string?)
	return true, nil
end

function AttackState.enter(context: any, fromState: string?)
	context.isAttacking = true

	task.spawn(function()
		local primaryPart = context.primaryPart
		local targetHrp = context.currentTargetHrp

		if primaryPart and targetHrp and targetHrp.Parent then
			-- Attack Lunge
			local attackDir = (targetHrp.Position - primaryPart.Position).Unit
			if context.moveToPosition then
				context.moveToPosition(context, primaryPart.Position + (attackDir * 3))
			end

			-- Invoke Attack Callback
			if context.onAttackHit then
				context.onAttackHit(targetHrp.Parent)
			end
		end

		task.wait(context.attackRecoveryTime or 0.5)
		context.isAttacking = false
	end)
end

function AttackState.exit(context: any, toState: string?)
end

function AttackState.update(context: any): string?
	if not context.isAttacking then
		return "Chase"
	end
	return nil
end

return AttackState
