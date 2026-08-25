--!nonstrict
--[[
    Transitions.luau
    Transition helper constructors for AnimationControllerV2 system.
    Location: src/client/Animation/Transitions.luau
--]]

local Transitions = {}

function Transitions.track(lane: string, owner: string, track: AnimationTrack, fadeTime: number?, disableDefaultAnimate: boolean?)
	return {
		kind = "Track",
		lane = lane,
		owner = owner,
		track = track,
		fadeTime = fadeTime,
		disableDefaultAnimate = disableDefaultAnimate,
	}
end

function Transitions.blend(
	lane: string,
	owner: string,
	trackGroup: { [string]: AnimationTrack },
	weights: { [string]: number },
	fadeTime: number?
)
	return {
		kind = "Blend",
		lane = lane,
		owner = owner,
		trackGroup = trackGroup,
		weights = weights,
		fadeTime = fadeTime,
	}
end

function Transitions.sequenceClip(
	lane: string,
	owner: string,
	trackGroups,
	sequenceIndex: number,
	clipIndex: number,
	fadeTime: number?
)
	return {
		kind = "SequenceClip",
		lane = lane,
		owner = owner,
		trackGroups = trackGroups,
		sequenceIndex = sequenceIndex,
		clipIndex = clipIndex,
		fadeTime = fadeTime,
	}
end

return table.freeze(Transitions)
