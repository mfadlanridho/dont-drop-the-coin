--!nonstrict
--[[
    DashingState.luau
    State definition for Dash Bump ability execution (0.3s duration) with Parabolic LinearVelocity constraint.
    Location: src/shared/Utils/States/DashingState.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local StateMachine = require(script.Parent.Parent:WaitForChild("StateMachine"))

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
		if humanoid and rootPart then
			-- Lock character steering direction during forward dash lunge
			humanoid.AutoRotate = false

			local duration = Config.DASH_DURATION
			local totalDistance = Config.DASH_DISTANCE
			local avgSpeed = totalDistance / math.max(0.05, duration)
			local forwardDirection = rootPart.CFrame.LookVector

			-- Clean up any pre-existing dash constraint
			local oldLV = rootPart:FindFirstChild("DashLinearVelocity")
			if oldLV then oldLV:Destroy() end
			local oldAtt = rootPart:FindFirstChild("DashAttachment")
			if oldAtt then oldAtt:Destroy() end

			-- Create Attachment & LinearVelocity physics constraint
			local att = Instance.new("Attachment")
			att.Name = "DashAttachment"
			att.Parent = rootPart
			context.dashAttachment = att

			local lv = Instance.new("LinearVelocity")
			lv.Name = "DashLinearVelocity"
			lv.Attachment0 = att
			lv.MaxForce = 100000
			lv.VectorVelocity = Vector3.zero
			lv.RelativeTo = Enum.ActuatorRelativeTo.World
			lv.Parent = rootPart
			context.dashLinearVelocity = lv

			-- Run Parabolic Velocity Easing Curve over 0.3s (Accelerate -> Decelerate -> 0)
			local startTime = os.clock()
			context.dashConnection = RunService.Heartbeat:Connect(function()
				local elapsed = os.clock() - startTime
				local t = math.clamp(elapsed / duration, 0, 1)

				-- Parabolic multiplier: 6 * t * (1 - t)
				local speedMultiplier = 6 * t * (1 - t)
				local currentSpeed = avgSpeed * speedMultiplier

				if lv and lv.Parent then
					lv.VectorVelocity = forwardDirection * currentSpeed
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
					track.Looped = false -- Explicitly disable looping for 1-shot skill animation!
					track:Play(0.05, 1, 1)

					-- Auto-clean track reference
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

		-- Clean up LinearVelocity physics constraint from rootPart directly
		local rootPart = context.rootPart
		if rootPart then
			local dashLV = rootPart:FindFirstChild("DashLinearVelocity")
			if dashLV then
				dashLV:Destroy()
			end
			local dashAtt = rootPart:FindFirstChild("DashAttachment")
			if dashAtt then
				dashAtt:Destroy()
			end

			-- Reset residual horizontal velocity momentum to prevent forward sliding
			rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
		end

		if context.dashLinearVelocity then
			context.dashLinearVelocity:Destroy()
			context.dashLinearVelocity = nil
		end
		if context.dashAttachment then
			context.dashAttachment:Destroy()
			context.dashAttachment = nil
		end

		-- Restore character steering when dash completes
		local humanoid = context.humanoid
		if humanoid then
			humanoid.AutoRotate = true
		end
	end,

	update = function(context)
		return nil
	end,
}

return DashingState
