--!nonstrict
--[[
    Runtime.luau
    Core animation runtime managing track loading, caching, playback lanes, and default animate overrides.
    Location: src/client/Animation/Runtime.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationSequenceUtils = require(script.Parent:WaitForChild("AnimationSequenceUtils"))
local AnimationTypes = require(script.Parent:WaitForChild("AnimationTypes"))
local AnimationTrackUtils = require(script.Parent:WaitForChild("AnimationTrackUtils"))
local Rig = require(script.Parent.Parent:WaitForChild("Rig"))

type TrackSet = { [string]: AnimationTrack }
type SequenceTrackSet = { [number]: AnimationTrack }
type NestedSequenceTrackSet = { [number]: SequenceTrackSet }
type AnimationSequenceList = AnimationTypes.AnimationSequenceList

export type TrackConfig = {
	name: string?,
	animationId: string,
	priority: Enum.AnimationPriority?,
	looped: boolean?,
}

export type FolderTrackGroupConfig = {
	cacheKey: string,
	folderName: string,
	names: { string },
	priority: Enum.AnimationPriority?,
	looped: boolean?,
}

export type IdTrackGroupConfig = {
	cacheKey: string,
	animationIds: { [string]: string },
	names: { string },
	priority: Enum.AnimationPriority?,
	looped: boolean?,
}

export type SequenceTrackGroupConfig = {
	cacheKey: string,
	sequences: AnimationSequenceList,
	namePrefix: string,
	priority: Enum.AnimationPriority?,
	allowEmpty: boolean?,
	loopedLastClip: boolean?,
}

type PlaybackLaneState = {
	name: string,
	activeTracks: { [any]: AnimationTrack },
	owner: string?,
}

type RuntimeState = {
	started: boolean,
	rig: typeof(Rig.getState()),
	disconnectRigObserver: (() -> ())?,
	currentAnimateScript: LocalScript?,
	animateEnabledSnapshot: boolean?,
	trackCache: { [string]: AnimationTrack },
	trackGroups: { [string]: TrackSet },
	sequenceTrackGroups: { [string]: NestedSequenceTrackSet },
	playbackLanes: { [string]: PlaybackLaneState },
	warnedMissingFolders: { [string]: boolean },
}

local Runtime = {}
Runtime.__index = Runtime

local DEFAULT_PRIORITY = Enum.AnimationPriority.Action4

local function normalizeFadeTime(fadeTime: number?): number
	if type(fadeTime) ~= "number" then
		return 0
	end
	return math.max(0, fadeTime)
end

local function createPlaybackLaneState(laneName: string): PlaybackLaneState
	return {
		name = laneName,
		activeTracks = {},
		owner = nil,
	}
end

function Runtime.new()
	local self = setmetatable({}, Runtime)

	self._state = {
		started = false,
		rig = Rig.getState(),
		disconnectRigObserver = nil,
		currentAnimateScript = nil,
		animateEnabledSnapshot = nil,
		trackCache = {},
		trackGroups = {},
		sequenceTrackGroups = {},
		playbackLanes = {},
		warnedMissingFolders = {},
	} :: RuntimeState

	return self
end

function Runtime:getRigState()
	return self._state.rig
end

function Runtime:getHumanoid(): Humanoid?
	return self._state.rig.humanoid
end

function Runtime:getAnimator(): Animator?
	local humanoid = self:getHumanoid()
	if humanoid == nil then
		return nil
	end
	return AnimationTrackUtils.getAnimator(humanoid)
end

function Runtime:start()
	if self._state.started then
		return
	end

	self._state.started = true
	Rig.start()

	self._state.disconnectRigObserver = Rig.observe(function()
		self:_onRigChanged()
	end)
end

function Runtime:stop()
	if not self._state.started then
		return
	end

	self._state.started = false

	if self._state.disconnectRigObserver ~= nil then
		self._state.disconnectRigObserver()
		self._state.disconnectRigObserver = nil
	end

	self:stopAllPlayback(0)
	self:restoreDefaultAnimate()
	self:clearTrackCaches()
end

function Runtime:disableDefaultAnimate()
	local rigState = self._state.rig
	if rigState.character == nil or self._state.currentAnimateScript ~= nil then
		return
	end

	local animateScript = rigState.character:FindFirstChild("Animate")
	if animateScript ~= nil and animateScript:IsA("LocalScript") then
		self._state.currentAnimateScript = animateScript
		self._state.animateEnabledSnapshot = animateScript.Enabled
		animateScript.Enabled = false
	end
end

function Runtime:restoreDefaultAnimate()
	if self._state.currentAnimateScript ~= nil
		and self._state.currentAnimateScript.Parent ~= nil
		and self._state.animateEnabledSnapshot ~= nil
	then
		self._state.currentAnimateScript.Enabled = self._state.animateEnabledSnapshot
	end

	self._state.currentAnimateScript = nil
	self._state.animateEnabledSnapshot = nil
end

function Runtime:getPlaybackLaneState(laneName: string): PlaybackLaneState
	local laneState = self._state.playbackLanes[laneName]
	if laneState == nil then
		laneState = createPlaybackLaneState(laneName)
		self._state.playbackLanes[laneName] = laneState
	end

	return laneState
end

function Runtime:hasActivePlayback(): boolean
	for _, laneState in pairs(self._state.playbackLanes) do
		if next(laneState.activeTracks) ~= nil then
			return true
		end
	end
	return false
end

function Runtime:stopPlaybackLane(laneName: string, fadeTime: number?)
	local laneState = self:getPlaybackLaneState(laneName)
	local fade = normalizeFadeTime(fadeTime)

	for key, track in pairs(laneState.activeTracks) do
		track:AdjustWeight(0, fade)
		track:Stop(fade)
		laneState.activeTracks[key] = nil
	end

	laneState.owner = nil
end

function Runtime:stopOwner(owner: string, fadeTime: number?)
	for laneName, laneState in pairs(self._state.playbackLanes) do
		if laneState.owner == owner then
			self:stopPlaybackLane(laneName, fadeTime)
		end
	end

	if not self:hasActivePlayback() then
		self:restoreDefaultAnimate()
	end
end

function Runtime:stopAllPlayback(fadeTime: number?)
	for laneName in pairs(self._state.playbackLanes) do
		self:stopPlaybackLane(laneName, fadeTime)
	end
	self:restoreDefaultAnimate()
end

function Runtime:ensureIdTrack(cacheKey: string, config: TrackConfig): AnimationTrack?
	local cachedTrack = self._state.trackCache[cacheKey]
	if cachedTrack ~= nil then
		return cachedTrack
	end

	local animator = self:getAnimator()
	if animator == nil then
		return nil
	end

	local animationId = config.animationId
	if type(animationId) ~= "string" or animationId == "" then
		return nil
	end

	local track = AnimationTrackUtils.createConfiguredTrack(
		animator,
		config.name or cacheKey,
		animationId,
		config.priority or DEFAULT_PRIORITY,
		config.looped == true
	)

	self._state.trackCache[cacheKey] = track
	return track
end

function Runtime:ensureSequenceTrackGroup(config: SequenceTrackGroupConfig): NestedSequenceTrackSet?
	local cachedGroup = self._state.sequenceTrackGroups[config.cacheKey]
	if cachedGroup ~= nil then
		return cachedGroup
	end

	local animator = self:getAnimator()
	if animator == nil then
		return nil
	end

	local trackGroup: NestedSequenceTrackSet = {}
	local created = AnimationSequenceUtils.ensureConfiguredSequenceTracks(
		animator,
		config.sequences,
		trackGroup,
		config.namePrefix,
		function(innerAnimator: Animator, trackName: string, animationId: string, loopedLastClip: boolean)
			return AnimationTrackUtils.createConfiguredTrack(
				innerAnimator,
				trackName,
				animationId,
				config.priority or DEFAULT_PRIORITY,
				if config.loopedLastClip == nil then loopedLastClip else config.loopedLastClip
			)
		end,
		config.allowEmpty
	)

	if not created then
		return nil
	end

	self._state.sequenceTrackGroups[config.cacheKey] = trackGroup
	return trackGroup
end

function Runtime:_playTrackOnLane(laneName: string, owner: string, track: AnimationTrack, fadeTime: number?)
	local laneState = self:getPlaybackLaneState(laneName)
	local fade = normalizeFadeTime(fadeTime)

	self:stopPlaybackLane(laneName, fade)

	track.TimePosition = 0
	track:AdjustSpeed(1)
	track:Play(fade, 1, 1)
	track:AdjustWeight(1, fade)

	laneState.activeTracks[1] = track
	laneState.owner = owner
end

function Runtime:_playSequenceClipOnLane(
	laneName: string,
	owner: string,
	trackGroups: NestedSequenceTrackSet,
	sequenceIndex: number,
	clipIndex: number,
	fadeTime: number?
): AnimationTrack?
	local track = AnimationSequenceUtils.getSequenceTrack(trackGroups, sequenceIndex, clipIndex)
	if track == nil then
		return nil
	end

	self:_playTrackOnLane(laneName, owner, track, fadeTime)
	return track
end

function Runtime:_activateBlendOnLane(
	laneName: string,
	owner: string,
	trackGroup: TrackSet,
	weights: { [string]: number },
	fadeTime: number?
)
	local laneState = self:getPlaybackLaneState(laneName)
	local fade = normalizeFadeTime(fadeTime)

	local activeTracks = {}
	for key, track in pairs(trackGroup) do
		if not track.IsPlaying then
			track:Play(fade, 1, 1)
		end

		track:AdjustWeight(math.max(0, weights[key] or 0), fade)
		activeTracks[key] = track
	end

	for key, track in pairs(laneState.activeTracks) do
		if activeTracks[key] == nil then
			track:AdjustWeight(0, fade)
			track:Stop(fade)
		end
	end

	laneState.activeTracks = activeTracks
	laneState.owner = owner
end

function Runtime:play(transition)
	local kind = transition.kind
	if kind == "Track" then
		if transition.disableDefaultAnimate == true then
			self:disableDefaultAnimate()
		end
		self:_playTrackOnLane(transition.lane, transition.owner, transition.track, transition.fadeTime)
		return transition.track
	end

	if kind == "Blend" then
		self:_activateBlendOnLane(
			transition.lane,
			transition.owner,
			transition.trackGroup,
			transition.weights,
			transition.fadeTime
		)
		return true
	end

	if kind == "SequenceClip" then
		return self:_playSequenceClipOnLane(
			transition.lane,
			transition.owner,
			transition.trackGroups,
			transition.sequenceIndex,
			transition.clipIndex,
			transition.fadeTime
		)
	end

	error(string.format("Animation.Runtime: unsupported transition kind %q", tostring(kind)))
end

function Runtime:clearTrackCaches()
	for cacheKey, track in pairs(self._state.trackCache) do
		track:Destroy()
		self._state.trackCache[cacheKey] = nil
	end

	for cacheKey, trackGroup in pairs(self._state.trackGroups) do
		for name, track in pairs(trackGroup) do
			track:Destroy()
			trackGroup[name] = nil
		end
		self._state.trackGroups[cacheKey] = nil
	end

	for cacheKey, nestedGroup in pairs(self._state.sequenceTrackGroups) do
		for _, trackGroup in pairs(nestedGroup) do
			for name, track in pairs(trackGroup) do
				track:Destroy()
				trackGroup[name] = nil
			end
		end
		self._state.sequenceTrackGroups[cacheKey] = nil
	end
end

function Runtime:_onRigChanged()
	self:stopAllPlayback(0)
	self:restoreDefaultAnimate()
	self:clearTrackCaches()
end

return Runtime
