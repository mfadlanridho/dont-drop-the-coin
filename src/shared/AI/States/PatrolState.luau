--!strict
--[[
    PatrolState.luau
    Universal Roblox AI Workspace Patrol State.
    Patrols between platform waypoints calling universal moveToPosition().
    When returning from chase or when platform becomes empty, smoothly moves back to startPos before idling.
    Location: src/shared/AI/States/PatrolState.luau
--]]

local Players = game:GetService("Players")

local PatrolState = {}
PatrolState.name = "Patrol"

function PatrolState.canEnter(context: any, fromState: string?): (boolean, string?)
	return true, nil
end

function PatrolState.enter(context: any, fromState: string?)
	context.patrolStartTime = os.clock()
	context.currentWaypointIndex = context.currentWaypointIndex or 1
end

function PatrolState.exit(context: any, toState: string?)
end

function PatrolState.update(context: any): string?
	local primaryPart = context.primaryPart
	if not primaryPart then return "Idle" end

	-- If guard is dormant (platform empty)
	if context.isDormant then
		local distToHome = (context.startPos - primaryPart.Position).Magnitude
		if distToHome > 2.0 then
			-- Smoothly move back to startPos before idling
			if context.moveToPosition then
				context.moveToPosition(context, context.startPos)
			end
			return nil
		else
			return "Idle"
		end
	end

	-- Scan for nearest player within detection radius
	local nearestHrp: BasePart? = nil
	local shortestDist = context.detectionRadius or 40

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local dist = (hrp.Position - primaryPart.Position).Magnitude
			if dist < shortestDist then
				shortestDist = dist
				nearestHrp = hrp
			end
		end
	end

	if nearestHrp then
		context.currentTargetHrp = nearestHrp
		return "Chase"
	end

	-- Universal Waypoint Patrol Movement
	local waypoints = context.waypoints
	if waypoints and #waypoints > 0 then
		local currentIdx = context.currentWaypointIndex or 1
		local targetWpPart = waypoints[currentIdx]

		if targetWpPart then
			local targetPos = targetWpPart.Position
			local distToWp = (targetPos - primaryPart.Position).Magnitude

			if distToWp <= 2.5 then
				context.currentWaypointIndex = (currentIdx % #waypoints) + 1
			else
				if context.moveToPosition then
					context.moveToPosition(context, targetPos)
				end
			end
		end
	else
		-- Hover patrol around startPos for non-waypoint AIs
		local elapsed = os.clock() - (context.patrolStartTime or os.clock())
		local targetHoverPos = context.startPos + Vector3.new(math.sin(elapsed * 1.5) * 8, math.cos(elapsed * 2) * 2, 0)
		if context.moveToPosition then
			context.moveToPosition(context, targetHoverPos)
		end
	end

	return nil
end

return PatrolState
