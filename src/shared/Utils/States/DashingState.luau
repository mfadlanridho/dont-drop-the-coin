--!nonstrict
--[[
    DashingState.luau
    State definition for Dash Bump ability execution (0.3s duration) using MovementMotor class.
    Location: src/shared/Utils/States/DashingState.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local StateMachine = require(script.Parent.Parent:WaitForChild("StateMachine"))

local MovementMotor: any
if RunService:IsClient() then
	local ClientScripts = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
	MovementMotor = require(ClientScripts:WaitForChild("MovementMotor"))
end

local motorInstance: any
if RunService:IsClient() then
	motorInstance = MovementMotor.new({
		attachmentName = "DashAttachment",
		linearVelocityName = "DashLinearVelocity",
	})
end

local DashingState: StateMachine.StateDefinition = {
	name = "Dashing",

	canEnter = function(context, fromState)
		if fromState == "Ragdolled" then
			return false, "cannot_dash_while_ragdolled"
		end
		if fromState == "SafeZone" then
			return false, "cannot_dash_in_safe_zone"
		end
		return true, nil
	end,

	enter = function(context, fromState)
		print(string.format("[DashingState] %s casting Dash Bump!", context.player and context.player.Name or "Unknown"))

		local humanoid = context.humanoid
		local rootPart = context.rootPart

		if RunService:IsClient() and humanoid and rootPart and motorInstance then
			-- Capture steering & ensure motor constraints
			motorInstance:capture(humanoid)
			motorInstance:ensure(rootPart)

			local duration = Config.DASH_DURATION
			local totalDistance = Config.DASH_DISTANCE
			local avgSpeed = totalDistance / math.max(0.05, duration)
			local forwardDirection = rootPart.CFrame.LookVector

			-- Run Parabolic Velocity Easing Curve over 0.3s (Accelerate -> Decelerate -> 0)
			local startTime = os.clock()
			context.dashConnection = RunService.Heartbeat:Connect(function()
				local elapsed = os.clock() - startTime
				local t = math.clamp(elapsed / duration, 0, 1)

				-- Parabolic multiplier: 6 * t * (1 - t)
				local speedMultiplier = 6 * t * (1 - t)
				local currentSpeed = avgSpeed * speedMultiplier

				if motorInstance.linearVelocity then
					motorInstance.linearVelocity.VectorVelocity = forwardDirection * currentSpeed
				end
			end)

			-- Play Dash Animation on Humanoid Animator
			if Config.DASH_ANIMATION_ID and Config.DASH_ANIMATION_ID ~= "" then
				local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
				if animator then
					local anim = Instance.new("Animation")
					anim.AnimationId = Config.DASH_ANIMATION_ID

					local track = animator:LoadAnimation(anim)
					track.Priority = Enum.AnimationPriority.Action
					track.Looped = false
					track:Play(0.05, 1, 1)

					anim:Destroy()
				end
			end
		end
	end,

	exit = function(context, toState)
		-- Disconnect Heartbeat velocity curve listener
		if context.dashConnection then
			context.dashConnection:Disconnect()
			context.dashConnection = nil
		end

		-- Clean up MovementMotor physics constraints cleanly
		if RunService:IsClient() and motorInstance then
			motorInstance:release(context.humanoid)
			motorInstance:destroy()
		end

		-- Reset residual horizontal velocity momentum to prevent forward sliding
		local rootPart = context.rootPart
		if rootPart then
			rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
		end
	end,

	update = function(context)
		return nil
	end,
}

return DashingState
