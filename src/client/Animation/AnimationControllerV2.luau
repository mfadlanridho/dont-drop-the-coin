--!nonstrict
--[[
    AnimationControllerV2.luau
    High-level animation controller handling preloading, clip sequences, and 2D directional blending.
    Location: src/client/Animation/AnimationControllerV2.luau
--]]

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local AnimationTypes = require(script.Parent:WaitForChild("AnimationTypes"))
local DirectionalMixerState = require(script.Parent:WaitForChild("DirectionalMixerState"))
local Runtime = require(script.Parent:WaitForChild("Runtime"))
local SequencePlayer = require(script.Parent:WaitForChild("SequencePlayer"))
local Transitions = require(script.Parent:WaitForChild("Transitions"))

local AnimationControllerV2 = {}
AnimationControllerV2.__index = AnimationControllerV2
AnimationControllerV2.Transitions = Transitions

local ACTIVE_SEQUENCE_OWNER = "__ActiveSequence"
local ACTIVE_SEQUENCE_LANE = "OneShot"
local ACTIVE_DIRECTIONAL_MIXER_OWNER = "__ActiveDirectionalMixer"
local ACTIVE_DIRECTIONAL_MIXER_LANE = "Base"

export type PlayAnimationSequenceOptions = {
	entryFadeTime: number?,
	holdLastClip: boolean?,
	priority: Enum.AnimationPriority?,
	allowEmpty: boolean?,
	loopedLastClip: boolean?,
}

export type PlayDirectionalMixerOptions = {
	folderName: string,
	names: { string },
	animationIds: { [string]: string }?,
	input: Vector2?,
	fadeTime: number?,
	priority: Enum.AnimationPriority?,
	looped: boolean?,
	disableDefaultAnimate: boolean?,
}

type DirectionalMixerStateHandle = AnimationTypes.DirectionalMixerStateHandle

export type AnimationControllerV2Instance = {
	_runtime: any,
	_activeSequencePlayer: any,
	_activeDirectionalMixerState: any,
	_heartbeatConnection: RBXScriptConnection?,
	start: (self: AnimationControllerV2Instance) -> (),
	stop: (self: AnimationControllerV2Instance) -> (),
	getRuntime: (self: AnimationControllerV2Instance) -> any,
	play: (self: AnimationControllerV2Instance, transition: any) -> any,
	playAnimationSequence: (self: AnimationControllerV2Instance, sequence: AnimationTypes.AnimationSequence, options: PlayAnimationSequenceOptions?) -> boolean,
	warmAnimationSequence: (self: AnimationControllerV2Instance, sequence: AnimationTypes.AnimationSequence, options: PlayAnimationSequenceOptions?) -> boolean,
	stopAnimationSequence: (self: AnimationControllerV2Instance, fadeTime: number?) -> (),
	playDirectionalMixer: (
		self: AnimationControllerV2Instance,
		buildWeights: (Vector2) -> { [string]: number },
		options: PlayDirectionalMixerOptions
	) -> DirectionalMixerStateHandle?,
	warmDirectionalMixer: (self: AnimationControllerV2Instance, options: PlayDirectionalMixerOptions) -> boolean,
	preloadAnimationIds: (self: AnimationControllerV2Instance, animationIds: { string }) -> (),
	stopDirectionalMixer: (self: AnimationControllerV2Instance, fadeTime: number?) -> (),
	stopOwner: (self: AnimationControllerV2Instance, owner: string, fadeTime: number?) -> (),
}

function AnimationControllerV2.new(): AnimationControllerV2Instance
	local self = setmetatable({}, AnimationControllerV2) :: any

	self._runtime = Runtime.new()
	self._activeSequencePlayer = nil
	self._activeDirectionalMixerState = nil
	self._heartbeatConnection = nil

	return self :: AnimationControllerV2Instance
end

function AnimationControllerV2.start(self: AnimationControllerV2Instance): ()
	self._runtime:start()

	if self._heartbeatConnection ~= nil then
		return
	end

	self._heartbeatConnection = RunService.Heartbeat:Connect(function()
		if self._activeSequencePlayer ~= nil then
			self._activeSequencePlayer:update()
		end
	end)
end

function AnimationControllerV2.stop(self: AnimationControllerV2Instance): ()
	if self._heartbeatConnection ~= nil then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end

	self._activeSequencePlayer = nil
	self._activeDirectionalMixerState = nil
	self._runtime:stop()
end

function AnimationControllerV2.getRuntime(self: AnimationControllerV2Instance): any
	return self._runtime
end

function AnimationControllerV2.play(self: AnimationControllerV2Instance, transition: any): any
	return self._runtime:play(transition)
end

function AnimationControllerV2.preloadAnimationIds(self: AnimationControllerV2Instance, animationIds: { string }): ()
	local animationsToPreload = {}
	for _, id in ipairs(animationIds) do
		if type(id) == "string" and id ~= "" then
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			table.insert(animationsToPreload, anim)
		end
	end

	if #animationsToPreload > 0 then
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync(animationsToPreload)
			end)
			for _, anim in ipairs(animationsToPreload) do
				anim:Destroy()
			end
		end)
	end
end

function AnimationControllerV2.playAnimationSequence(
	self: AnimationControllerV2Instance,
	sequence: AnimationTypes.AnimationSequence,
	options: PlayAnimationSequenceOptions?
): boolean
	local sequences = { sequence }
	local cacheKey = string.format("seq_%s", tostring(sequence[1]))

	local trackGroup = self._runtime:ensureSequenceTrackGroup({
		cacheKey = cacheKey,
		sequences = sequences,
		namePrefix = "SeqClip_",
		priority = options and options.priority or Enum.AnimationPriority.Action,
		allowEmpty = options and options.allowEmpty,
		loopedLastClip = options and options.loopedLastClip,
	})

	if trackGroup == nil then
		return false
	end

	local sequencePlayer = SequencePlayer.new(self._runtime, ACTIVE_SEQUENCE_LANE, ACTIVE_SEQUENCE_OWNER)
	local started = sequencePlayer:play(trackGroup, sequences, {
		entryFadeTime = options and options.entryFadeTime or 0.1,
		holdLastClip = options and options.holdLastClip,
	})

	if started then
		self._activeSequencePlayer = sequencePlayer
	end

	return started
end

function AnimationControllerV2.stopAnimationSequence(self: AnimationControllerV2Instance, fadeTime: number?): ()
	if self._activeSequencePlayer ~= nil then
		self._activeSequencePlayer:stop(fadeTime or 0.1)
		self._activeSequencePlayer = nil
	end
end

function AnimationControllerV2.stopOwner(self: AnimationControllerV2Instance, owner: string, fadeTime: number?): ()
	self._runtime:stopOwner(owner, fadeTime)
end

return AnimationControllerV2
