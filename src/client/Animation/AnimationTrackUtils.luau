--!nonstrict
--[[
    AnimationTrackUtils.luau
    Utility functions for managing Animator tracks and sets.
    Location: src/client/Animation/AnimationTrackUtils.luau
--]]

local AnimationTrackUtils = {}

export type TrackSet = { [string]: AnimationTrack }
export type SequenceTrackSet = { [number]: AnimationTrack }
export type NestedSequenceTrackSet = { [number]: SequenceTrackSet }

function AnimationTrackUtils.getAnimator(humanoid: Humanoid): Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator == nil then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

function AnimationTrackUtils.createConfiguredTrack(
	animator: Animator,
	name: string,
	animationId: string,
	priority: Enum.AnimationPriority,
	looped: boolean
): AnimationTrack
	local animation = Instance.new("Animation")
	animation.Name = name
	animation.AnimationId = animationId

	local track = animator:LoadAnimation(animation)
	track.Name = name
	track.Priority = priority
	track.Looped = looped

	animation:Destroy()
	return track
end

function AnimationTrackUtils.stopTrackSet(trackSet: { [any]: AnimationTrack }, fadeTime: number)
	for _, track in pairs(trackSet) do
		track:AdjustWeight(0, fadeTime)
		track:Stop(fadeTime)
	end
end

function AnimationTrackUtils.stopNestedTrackSet(trackGroups: { [any]: { [any]: AnimationTrack } }, fadeTime: number)
	for _, trackSet in pairs(trackGroups) do
		AnimationTrackUtils.stopTrackSet(trackSet, fadeTime)
	end
end

function AnimationTrackUtils.clearTrackSet(trackSet: { [any]: AnimationTrack })
	AnimationTrackUtils.stopTrackSet(trackSet, 0)
	for name, track in pairs(trackSet) do
		track:Destroy()
		trackSet[name] = nil
	end
end

function AnimationTrackUtils.clearNestedTrackSet(trackGroups: { [any]: { [any]: AnimationTrack } })
	for name, trackSet in pairs(trackGroups) do
		AnimationTrackUtils.clearTrackSet(trackSet)
		trackGroups[name] = nil
	end
end

function AnimationTrackUtils.setExclusiveTrackWeight(
	trackSet: { [any]: AnimationTrack },
	selectedTrack: AnimationTrack?,
	fadeTime: number
)
	for _, track in pairs(trackSet) do
		track:AdjustWeight(if track == selectedTrack then 1 else 0, fadeTime)
	end
end

function AnimationTrackUtils.setExclusiveNestedTrackWeight(
	trackGroups: { [any]: { [any]: AnimationTrack } },
	selectedTrack: AnimationTrack?,
	fadeTime: number
)
	for _, trackSet in pairs(trackGroups) do
		AnimationTrackUtils.setExclusiveTrackWeight(trackSet, selectedTrack, fadeTime)
	end
end

return AnimationTrackUtils
