--!strict
--[[
    GameplayAudio.luau
    Central audio manager module for playing 2D/3D one-shot sound effects and tracked looped sounds.
    Location: src/shared/Utils/GameplayAudio.luau
--]]

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared:WaitForChild("Config"):WaitForChild("SoundConfig") :: ModuleScript)

local GameplayAudio = {}
local activeLoops: { [string]: Sound } = {}

-- Helper to resolve sound instance or Asset ID from a string key or Instance
local function resolveSoundIdAndVolume(soundInput: any): (string?, number, number)
	if typeof(soundInput) == "Instance" and soundInput:IsA("Sound") then
		return soundInput.SoundId, soundInput.Volume, soundInput.PlaybackSpeed
	elseif typeof(soundInput) == "string" then
		-- Check SoundConfig registry
		local def = SoundConfig.Sounds[soundInput]
		if def then
			return def.Id, def.Volume, def.Pitch or 1.0
		end

		-- Format raw asset ID or URL
		if string.match(soundInput, "^rbxassetid://") or string.match(soundInput, "^http") then
			return soundInput, 0.5, 1.0
		elseif string.match(soundInput, "^%d+$") then
			return "rbxassetid://" .. soundInput, 0.5, 1.0
		end
	end

	return nil, 0.5, 1.0
end

--[[
    Plays a 2D or 3D one-shot sound effect.
    - If `parent` is provided (e.g. BasePart/Attachment), it plays as 3D spatial audio.
    - If `parent` is nil, it plays as 2D UI audio parented to SoundService.
--]]
function GameplayAudio.playOneShot(
	soundInput: any,
	parent: Instance?,
	volumeOverride: number?,
	pitchOverride: number?
): Sound?
	if soundInput == nil then
		return nil
	end

	local soundId, defaultVol, defaultPitch = resolveSoundIdAndVolume(soundInput)
	if not soundId then
		return nil
	end

	local sound = Instance.new("Sound")
	sound.Name = "GameplayAudio_OneShot"
	sound.SoundId = soundId
	sound.Volume = volumeOverride or defaultVol
	sound.PlaybackSpeed = pitchOverride or defaultPitch
	sound.Parent = parent or SoundService

	sound:Play()

	-- Clean up sound instance after playback ends
	local duration = sound.TimeLength > 0 and sound.TimeLength + 0.5 or 10
	Debris:AddItem(sound, duration)

	return sound
end

--[[
    Plays a looped sound tracked by a unique string ID.
--]]
function GameplayAudio.playLooped(
	loopId: string,
	soundInput: any,
	parent: Instance?,
	volumeOverride: number?,
	pitchOverride: number?
): Sound?
	if activeLoops[loopId] then
		return activeLoops[loopId]
	end

	local soundId, defaultVol, defaultPitch = resolveSoundIdAndVolume(soundInput)
	if not soundId then
		return nil
	end

	local sound = Instance.new("Sound")
	sound.Name = "GameplayAudio_Loop_" .. loopId
	sound.SoundId = soundId
	sound.Looped = true
	sound.Volume = volumeOverride or defaultVol
	sound.PlaybackSpeed = pitchOverride or defaultPitch
	sound.Parent = parent or SoundService

	sound:Play()
	activeLoops[loopId] = sound

	return sound
end

--[[
    Stops and destroys a tracked looped sound by its unique ID.
    Supports optional fade-out duration before destruction.
--]]
function GameplayAudio.stopLooped(loopId: string, fadeOutTime: number?)
	local soundInstance = activeLoops[loopId]
	if not soundInstance then
		return
	end

	activeLoops[loopId] = nil

	if fadeOutTime and fadeOutTime > 0 then
		local fadeTween = TweenService:Create(
			soundInstance,
			TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Volume = 0 }
		)
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			soundInstance:Stop()
			soundInstance:Destroy()
		end)
	else
		soundInstance:Stop()
		soundInstance:Destroy()
	end
end

--[[
    Checks if a looped audio track is currently active.
--]]
function GameplayAudio.isLoopActive(loopId: string): boolean
	return activeLoops[loopId] ~= nil
end

return GameplayAudio
