--!strict
--[[
    AttackState.luau
    Generic reusable Attack State for NPC Guard AI.
    Executes lunge attack action, triggers onAttackHit callback, and transitions back to Chase.
    Location: src/server/NPCAI/States/AttackState.luau
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
			-- Lunge Forward
			local attackDir = (targetHrp.Position - primaryPart.Position).Unit
			primaryPart.CFrame = primaryPart.CFrame * CFrame.new(attackDir * 3)

			-- Invoke Custom Attack Callback
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
