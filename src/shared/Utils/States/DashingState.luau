--!nonstrict
--[[
    DashingState.luau
    State definition for Dash Bump ability execution (0.3s duration) with AnimationControllerV2 integration.
    Location: src/shared/Utils/States/DashingState.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

		-- Play Dash Animation on Humanoid Animator
		local humanoid = context.humanoid
		if humanoid and Config.DASH_ANIMATION_ID and Config.DASH_ANIMATION_ID ~= "" then
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
	end,

	exit = function(context, toState)
	end,

	update = function(context)
		return nil
	end,
}

return DashingState
