--!strict
--[[
    PatrolState.luau
    Generic reusable Patrol State for NPC Guard AI.
    Handles hover/waypoint patrol movement and scans for target players within detection radius.
    Location: src/server/NPCAI/States/PatrolState.luau
--]]

local Players = game:GetService("Players")

export type PatrolContext = {
	model: Model,
	primaryPart: BasePart,
	startPos: Vector3,
	detectionRadius: number,
	currentTargetHrp: BasePart?,
	patrolStartTime: number,
}

local PatrolState = {}
PatrolState.name = "Patrol"

function PatrolState.canEnter(context: any, fromState: string?): (boolean, string?)
	return true, nil
end

function PatrolState.enter(context: any, fromState: string?)
	context.patrolStartTime = os.clock()
end

function PatrolState.exit(context: any, toState: string?)
end

function PatrolState.update(context: any): string?
	local primaryPart = context.primaryPart
	if not primaryPart then return nil end

	-- Scan for nearest target within detection radius
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

	-- Patrol Movement (Sine-wave hover around start position)
	local elapsed = os.clock() - (context.patrolStartTime or os.clock())
	local hoverPos = context.startPos + Vector3.new(math.sin(elapsed * 1.5) * 10, math.cos(elapsed * 2) * 2, 0)
	local currentPos = primaryPart.Position
	local moveDir = (hoverPos - currentPos)
	if moveDir.Magnitude > 0.1 then
		primaryPart.CFrame = CFrame.new(currentPos + (moveDir * 0.05), currentPos + moveDir)
	end

	return nil
end

return PatrolState
