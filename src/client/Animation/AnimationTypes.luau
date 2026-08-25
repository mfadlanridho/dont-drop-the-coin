--!nonstrict
--[[
    AnimationTypes.luau
    Type definitions for AnimationControllerV2 system.
    Location: src/client/Animation/AnimationTypes.luau
--]]

local AnimationTypes = {}

export type TrackSet = { [string]: AnimationTrack }
export type SequenceTrackSet = { [number]: AnimationTrack }
export type NestedSequenceTrackSet = { [number]: SequenceTrackSet }

export type AnimationClipConfig = {
	id: string,
	normalizedEndTime: number?,
	crossfadeToNextDuration: number?,
}

export type AnimationSequenceEntry = string | AnimationClipConfig
export type AnimationSequence = { AnimationSequenceEntry }
export type AnimationSequenceList = { AnimationSequence }
export type NamedAnimationSequenceSet = { [string]: AnimationSequence }

export type DirectionalMixerStateHandle = {
	play: (self: DirectionalMixerStateHandle, initialInput: Vector2?) -> boolean,
	setInput: (self: DirectionalMixerStateHandle, input: Vector2) -> boolean,
	getInput: (self: DirectionalMixerStateHandle) -> Vector2,
	stop: (self: DirectionalMixerStateHandle, fadeTime: number?) -> (),
}

return AnimationTypes
