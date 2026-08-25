--!nonstrict
--[[
    DirectionalMixerState.luau
    Handles 2D directional locomotion weight blending for animations.
    Location: src/client/Animation/DirectionalMixerState.luau
--]]

local Transitions = require(script.Parent:WaitForChild("Transitions"))

export type BuildWeights = (Vector2) -> { [string]: number }
export type DirectionalMixerState = {
	_runtime: any,
	_laneName: string,
	_owner: string,
	_trackGroup: { [string]: AnimationTrack },
	_buildWeights: BuildWeights,
	_fadeTime: number?,
	_input: Vector2,
	play: (self: DirectionalMixerState, initialInput: Vector2?) -> boolean,
	setInput: (self: DirectionalMixerState, input: Vector2) -> boolean,
	getInput: (self: DirectionalMixerState) -> Vector2,
	stop: (self: DirectionalMixerState, fadeTime: number?) -> (),
}

local DirectionalMixerState = {}
DirectionalMixerState.__index = DirectionalMixerState

function DirectionalMixerState.new(
	runtime: any,
	laneName: string,
	owner: string,
	trackGroup: { [string]: AnimationTrack },
	buildWeights: BuildWeights,
	fadeTime: number?
): DirectionalMixerState
	local self = setmetatable({}, DirectionalMixerState :: any) :: any

	self._runtime = runtime
	self._laneName = laneName
	self._owner = owner
	self._trackGroup = trackGroup
	self._buildWeights = buildWeights
	self._fadeTime = fadeTime
	self._input = Vector2.zero

	return self
end

function DirectionalMixerState.play(self: DirectionalMixerState, initialInput: Vector2?): boolean
	return self:setInput(initialInput or Vector2.zero)
end

function DirectionalMixerState.setInput(self: DirectionalMixerState, input: Vector2): boolean
	self._input = input
	self._runtime:play(Transitions.blend(
		self._laneName,
		self._owner,
		self._trackGroup,
		self._buildWeights(input),
		self._fadeTime
	))
	return true
end

function DirectionalMixerState.getInput(self: DirectionalMixerState): Vector2
	return self._input
end

function DirectionalMixerState.stop(self: DirectionalMixerState, fadeTime: number?)
	self._runtime:stopOwner(self._owner, if fadeTime ~= nil then fadeTime else self._fadeTime)
end

return DirectionalMixerState
