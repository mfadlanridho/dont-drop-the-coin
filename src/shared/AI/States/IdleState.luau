--!strict
--[[
    IdleState.luau
    Universal Guard AI Idle State.
    Dormant standby state; monitors platform zone entry and vision range scans.
    Location: src/shared/AI/States/IdleState.luau
--]]

local Players = game:GetService("Players")

local IdleState = {}
IdleState.name = "Idle"

function IdleState.canEnter(context: any, fromState: string?): (boolean, string?)
	return true, nil
end

function IdleState.enter(context: any, fromState: string?)
	-- Stop movement if humanoid exists
	if context.humanoid then
		context.humanoid:MoveTo(context.primaryPart.Position)
	end
end

function IdleState.exit(context: any, toState: string?)
end

function IdleState.update(context: any): string?
	-- If guard is dormant (platform empty), pause updates
	if context.isDormant then
		return nil
	end

	local primaryPart = context.primaryPart
	if not primaryPart then return nil end

	-- Vision scan for nearest player within detection radius
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

	-- Transition to Patrol if waypoints exist
	if context.waypoints and #context.waypoints > 0 then
		return "Patrol"
	end

	return nil
end

return IdleState
