--!strict
--[[
    ChaseState.luau
    Universal Roblox AI Workspace Chase State.
    Pursues target player at moveSpeed studs/sec calling universal moveToPosition().
    Location: src/shared/AI/States/ChaseState.luau
--]]

local ChaseState = {}
ChaseState.name = "Chase"

function ChaseState.canEnter(context: any, fromState: string?): (boolean, string?)
	return context.currentTargetHrp ~= nil, "no_target"
end

function ChaseState.enter(context: any, fromState: string?)
	context.lastTargetTime = os.clock()
end

function ChaseState.exit(context: any, toState: string?)
end

function ChaseState.update(context: any): string?
	-- If platform became empty or guard dormant, transition to Patrol
	if context.isDormant then
		context.currentTargetHrp = nil
		return "Patrol"
	end

	local primaryPart = context.primaryPart
	local targetHrp = context.currentTargetHrp

	if not primaryPart or not targetHrp or not targetHrp.Parent or not targetHrp:IsDescendantOf(workspace) then
		context.currentTargetHrp = nil
		return "Patrol"
	end

	local dist = (targetHrp.Position - primaryPart.Position).Magnitude

	-- Check for attack distance
	if dist <= (context.attackRadius or 5.0) then
		return "Attack"
	end

	-- Check for target escape (> detectionRadius + 20 or 3s loss)
	local maxDist = (context.detectionRadius or 40) + 20
	if dist > maxDist then
		if (os.clock() - context.lastTargetTime) > 3.0 then
			context.currentTargetHrp = nil
			return "Patrol"
		end
	else
		context.lastTargetTime = os.clock()
	end

	-- Universal Pursuit Movement
	local targetPos = targetHrp.Position
	if context.moveToPosition then
		context.moveToPosition(context, targetPos)
	end

	return nil
end

return ChaseState
