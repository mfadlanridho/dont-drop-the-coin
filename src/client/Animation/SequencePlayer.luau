--!nonstrict
--[[
    SequencePlayer.luau
    Manages clip-to-clip animation sequence playback and crossfading.
    Location: src/client/Animation/SequencePlayer.luau
--]]

local AnimationTypes = require(script.Parent:WaitForChild("AnimationTypes"))
local AnimationSequenceUtils = require(script.Parent:WaitForChild("AnimationSequenceUtils"))
local Transitions = require(script.Parent:WaitForChild("Transitions"))

export type SequencePlayerOptions = {
	entryFadeTime: number?,
	holdLastClip: boolean?,
	sequenceIndex: number?,
}

type AnimationSequenceList = AnimationTypes.AnimationSequenceList

local SequencePlayer = {}
SequencePlayer.__index = SequencePlayer

function SequencePlayer.new(runtime, laneName: string, owner: string)
	local self = setmetatable({}, SequencePlayer)

	self._runtime = runtime
	self._laneName = laneName
	self._owner = owner
	self._trackGroups = nil
	self._sequences = nil
	self._sequenceIndex = nil
	self._clipIndex = nil
	self._holdLastClip = false
	self._completed = false

	return self
end

function SequencePlayer:play(trackGroups, sequences: AnimationSequenceList, options: SequencePlayerOptions?)
	local sequenceIndex = if options ~= nil and options.sequenceIndex ~= nil then options.sequenceIndex else 1
	if AnimationSequenceUtils.getSequenceLength(sequences, sequenceIndex) == 0 then
		self:stop(0)
		return false
	end

	self._trackGroups = trackGroups
	self._sequences = sequences
	self._sequenceIndex = sequenceIndex
	self._clipIndex = 1
	self._holdLastClip = if options ~= nil then options.holdLastClip == true else false
	self._completed = false

	self._runtime:play(Transitions.sequenceClip(
		self._laneName,
		self._owner,
		trackGroups,
		sequenceIndex,
		1,
		if options ~= nil then options.entryFadeTime else nil
	))

	return true
end

function SequencePlayer:update()
	if self._completed or self._trackGroups == nil or self._sequences == nil then
		return false
	end

	local sequenceIndex = self._sequenceIndex
	local clipIndex = self._clipIndex
	if sequenceIndex == nil or clipIndex == nil then
		return false
	end

	local currentTrack = AnimationSequenceUtils.getSequenceTrack(self._trackGroups, sequenceIndex, clipIndex)
	if currentTrack == nil then
		return false
	end

	if AnimationSequenceUtils.isLastClip(self._sequences, sequenceIndex, clipIndex) then
		if self._holdLastClip or currentTrack.IsPlaying then
			return true
		end
		self._completed = true
		return false
	end

	local clipConfig = AnimationSequenceUtils.getClipConfig(self._sequences, sequenceIndex, clipIndex)
	if clipConfig == nil then
		return false
	end

	local normalizedEndTime = math.clamp(clipConfig.normalizedEndTime or 1, 0, 1)
	local normalizedTime = 0
	if currentTrack.Length > 0 then
		normalizedTime = currentTrack.TimePosition / currentTrack.Length
	end

	if not currentTrack.IsPlaying or normalizedTime >= normalizedEndTime then
		local nextClipIndex = clipIndex + 1
		self._runtime:play(Transitions.sequenceClip(
			self._laneName,
			self._owner,
			self._trackGroups,
			sequenceIndex,
			nextClipIndex,
			clipConfig.crossfadeToNextDuration
		))
		self._clipIndex = nextClipIndex
	end

	return true
end

function SequencePlayer:stop(fadeTime: number?)
	self._runtime:stopOwner(self._owner, fadeTime)
	self._trackGroups = nil
	self._sequences = nil
	self._sequenceIndex = nil
	self._clipIndex = nil
	self._holdLastClip = false
	self._completed = false
end

function SequencePlayer:isComplete(): boolean
	return self._completed
end

function SequencePlayer:isPlaying(): boolean
	return self._trackGroups ~= nil and not self._completed
end

return SequencePlayer
