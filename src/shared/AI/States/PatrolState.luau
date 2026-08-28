--!strict
--[[
    PatrolState.luau
    Universal Roblox AI Workspace Patrol State.
    Patrols between platform waypoints using native Humanoid:MoveTo().
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
	if context.humanoid then
		context.humanoid.WalkSpeed = context.moveSpeed or 16
	end
end

function PatrolState.exit(context: any, toState: string?)
end

function PatrolState.update(context: any): string?
	local primaryPart = context.primaryPart
	local humanoid = context.humanoid
	if not primaryPart or not humanoid then return nil end

	-- Scan for nearest target player standing on the platform floor
	local nearestHrp: BasePart? = nil
	local shortestDist = context.detectionRadius or 40

	for _, player in ipairs(Players:GetPlayers()) do
		if context.isPlayerOnPlatform and context.isPlayerOnPlatform(player, context.platformPart) then
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
	end

	if nearestHrp then
		context.currentTargetHrp = nearestHrp
		return "Chase"
	end

	-- Humanoid Waypoint Patrol Movement
	local waypoints = context.waypoints
	if waypoints and #waypoints > 0 then
		local currentIdx = context.currentWaypointIndex or 1
		local targetWpPart = waypoints[currentIdx]

		if targetWpPart then
			local targetPos = targetWpPart.Position
			local distToWp = (targetPos - primaryPart.Position).Magnitude

			if distToWp <= 3.0 then
				context.currentWaypointIndex = (currentIdx % #waypoints) + 1
			else
				humanoid:MoveTo(targetPos)
			end
		end
	else
		-- Hover/Walk patrol around startPos
		local elapsed = os.clock() - (context.patrolStartTime or os.clock())
		local targetHoverPos = context.startPos + Vector3.new(math.sin(elapsed * 1.5) * 8, 0, math.cos(elapsed * 1.5) * 8)
		humanoid:MoveTo(targetHoverPos)
	end

	return nil
end

return PatrolState
