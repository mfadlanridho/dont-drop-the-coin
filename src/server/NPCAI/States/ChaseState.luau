--!strict
--[[
    ChaseState.luau
    Generic reusable Chase State for NPC Guard AI.
    Pursues target player at moveSpeed; transitions to Attack when within attackRadius or returns to Patrol if target escapes.
    Location: src/server/NPCAI/States/ChaseState.luau
--]]

export type ChaseContext = {
	model: Model,
	primaryPart: BasePart,
	detectionRadius: number,
	moveSpeed: number,
	attackRadius: number,
	currentTargetHrp: BasePart?,
	lastTargetTime: number,
}

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
	local primaryPart = context.primaryPart
	local targetHrp = context.currentTargetHrp

	if not primaryPart or not targetHrp or not targetHrp.Parent or not targetHrp:IsDescendantOf(workspace) then
		context.currentTargetHrp = nil
		return "Patrol"
	end

	local dist = (targetHrp.Position - primaryPart.Position).Magnitude

	-- Check for attack trigger
	if dist <= (context.attackRadius or 5.0) then
		return "Attack"
	end

	-- Target escape check (> detectionRadius + 20 or 3s loss)
	local maxDist = (context.detectionRadius or 40) + 20
	if dist > maxDist then
		if (os.clock() - context.lastTargetTime) > 3.0 then
			context.currentTargetHrp = nil
			return "Patrol"
		end
	else
		context.lastTargetTime = os.clock()
	end

	-- Pursue target player @ moveSpeed studs/sec
	local targetPos = targetHrp.Position + Vector3.new(0, 2, 0)
	local currentPos = primaryPart.Position
	local moveDir = (targetPos - currentPos)
	if moveDir.Magnitude > 0.5 then
		local stepPos = currentPos + (moveDir.Unit * math.min(moveDir.Magnitude, (context.moveSpeed or 16) * (1/60)))
		primaryPart.CFrame = CFrame.new(stepPos, stepPos + moveDir)
	end

	return nil
end

return ChaseState
