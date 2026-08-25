--!nonstrict
--[[
    AnimationSequenceUtils.luau
    Utility functions for parsing animation sequences and clips.
    Location: src/client/Animation/AnimationSequenceUtils.luau
--]]

local AnimationTypes = require(script.Parent:WaitForChild("AnimationTypes"))

local AnimationSequenceUtils = {}

type AnimationClipConfig = AnimationTypes.AnimationClipConfig
type AnimationSequence = AnimationTypes.AnimationSequence
type AnimationSequenceList = AnimationTypes.AnimationSequenceList

function AnimationSequenceUtils.getSequence(sequences: AnimationSequenceList, index: number): AnimationSequence?
	local sequence = sequences[index]
	if type(sequence) ~= "table" then
		return nil
	end
	return sequence
end

function AnimationSequenceUtils.getClipConfig(
	sequences: AnimationSequenceList,
	sequenceIndex: number,
	clipIndex: number
): AnimationClipConfig?
	local sequence = AnimationSequenceUtils.getSequence(sequences, sequenceIndex)
	if sequence == nil then
		return nil
	end

	local clip = sequence[clipIndex]
	if type(clip) == "string" then
		return { id = clip }
	end

	if type(clip) ~= "table" then
		return nil
	end

	return clip
end

function AnimationSequenceUtils.getSequenceLength(sequences: AnimationSequenceList, sequenceIndex: number): number
	local sequence = AnimationSequenceUtils.getSequence(sequences, sequenceIndex)
	if sequence == nil then
		return 0
	end
	return #sequence
end

function AnimationSequenceUtils.getSequenceTrack(trackGroups, sequenceIndex: number?, clipIndex: number?): AnimationTrack?
	if sequenceIndex == nil or clipIndex == nil then
		return nil
	end

	local trackSet = trackGroups[sequenceIndex]
	if trackSet == nil then
		return nil
	end

	return trackSet[clipIndex]
end

function AnimationSequenceUtils.isLastClip(sequences: AnimationSequenceList, sequenceIndex: number, clipIndex: number): boolean
	return clipIndex >= AnimationSequenceUtils.getSequenceLength(sequences, sequenceIndex)
end

function AnimationSequenceUtils.ensureConfiguredSequenceTracks(
	animator: Animator,
	sequences: AnimationSequenceList,
	trackGroups,
	namePrefix: string,
	createTrack: (Animator, string, string, boolean) -> AnimationTrack,
	allowEmpty: boolean?,
	emptyWarning: string?,
	invalidSequenceWarningBuilder: ((number) -> string)?,
	missingClipWarningBuilder: ((number, number) -> string)?
): boolean
	if #sequences == 0 then
		if allowEmpty then
			return true
		end
		if emptyWarning ~= nil then
			warn(emptyWarning)
		end
		return false
	end

	for sequenceIndex, sequence in ipairs(sequences) do
		if type(sequence) ~= "table" or #sequence == 0 then
			if invalidSequenceWarningBuilder ~= nil then
				warn(invalidSequenceWarningBuilder(sequenceIndex))
			end
			return false
		end

		local sequenceTracks = trackGroups[sequenceIndex]
		if sequenceTracks == nil then
			sequenceTracks = {}
			trackGroups[sequenceIndex] = sequenceTracks
		end

		for clipIndex = 1, #sequence do
			if sequenceTracks[clipIndex] == nil then
				local clipConfig = AnimationSequenceUtils.getClipConfig(sequences, sequenceIndex, clipIndex)
				local animationId = if clipConfig ~= nil then clipConfig.id else nil
				if type(animationId) ~= "string" or animationId == "" then
					if missingClipWarningBuilder ~= nil then
						warn(missingClipWarningBuilder(sequenceIndex, clipIndex))
					end
					return false
				end

				sequenceTracks[clipIndex] = createTrack(
					animator,
					string.format("%s%d_%d", namePrefix, sequenceIndex, clipIndex),
					animationId,
					clipIndex == #sequence
				)
			end
		end
	end

	return true
end

return AnimationSequenceUtils
