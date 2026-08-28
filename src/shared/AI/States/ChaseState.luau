--!strict
--[[
    ChaseState.luau
    Universal Roblox AI Workspace Chase State.
    Pursues target player calling native Humanoid:MoveTo().
    Location: src/shared/AI/States/ChaseState.luau
--]]

local Players = game:GetService("Players")

local ChaseState = {}
ChaseState.name = "Chase"

function ChaseState.canEnter(context: any, fromState: string?): (boolean, string?)
	return context.currentTargetHrp ~= nil, "no_target"
end

function ChaseState.enter(context: any, fromState: string?)
	context.lastTargetTime = os.clock()
	if context.humanoid then
		context.humanoid.WalkSpeed = (context.moveSpeed or 16) + 2
	end
end

function ChaseState.exit(context: any, toState: string?)
	-- Instantly cancel active chase MoveTo navigation when exiting Chase state
	if context.humanoid and context.primaryPart then
		context.humanoid:MoveTo(context.primaryPart.Position)
	end
end

function ChaseState.update(context: any): string?
	local primaryPart = context.primaryPart
	local humanoid = context.humanoid
	local targetHrp = context.currentTargetHrp

	if not primaryPart or not humanoid or not targetHrp or not targetHrp.Parent or not targetHrp:IsDescendantOf(workspace) then
		context.currentTargetHrp = nil
		return "Patrol"
	end

	-- Validate that target player is strictly standing inside the platform floor boundary
	local targetPlayer = Players:GetPlayerFromCharacter(targetHrp.Parent)
	if targetPlayer and context.isPlayerOnPlatform then
		if not context.isPlayerOnPlatform(targetPlayer, context.platformPart) then
			context.currentTargetHrp = nil
			return "Patrol"
		end
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

	-- Native Humanoid Pursuit Movement
	humanoid:MoveTo(targetHrp.Position)

	return nil
end

return ChaseState
