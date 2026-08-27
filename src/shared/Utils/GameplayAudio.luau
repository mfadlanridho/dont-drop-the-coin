--!strict
--[[
    GameplayAudio.luau
    Central audio manager module for playing 2D/3D one-shot sound effects, tracked looped sounds, combo pitch scaling, and BGM playlist management.
    Prioritizes reading physical Sound instances placed in ReplicatedStorage.Audio so designers can visually edit audio properties in Studio Explorer.
    Location: src/shared/Utils/GameplayAudio.luau
--]]

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared:WaitForChild("Config"):WaitForChild("SoundConfig") :: ModuleScript)
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)

local log = Logger.create("Audio")

local GameplayAudio = {}
local activeLoops: { [string]: Sound } = {}

-- SoundGroup Channels
local masterGroup: SoundGroup? = nil
local sfxGroup: SoundGroup? = nil
local musicGroup: SoundGroup? = nil

-- Combo Pitch State
local comboCount = 0
local lastPickupTime = 0
local COMBO_WINDOW_SECONDS = 3.0
local PITCH_STEP = 0.05
local MAX_PITCH = 1.5

-- BGM State
local currentBgmTrack: Sound? = nil
local currentPlaylistIndex = 1
local isPlaylistActive = false

-- Initialize SoundGroup channels under SoundService
function GameplayAudio.initSoundGroups()
	masterGroup = SoundService:FindFirstChild("Master") :: SoundGroup
	if not masterGroup then
		masterGroup = Instance.new("SoundGroup")
		masterGroup.Name = "Master"
		masterGroup.Volume = SoundConfig.DefaultMasterVolume or 1.0
		masterGroup.Parent = SoundService
	end

	sfxGroup = masterGroup:FindFirstChild("SFX") :: SoundGroup
	if not sfxGroup then
		sfxGroup = Instance.new("SoundGroup")
		sfxGroup.Name = "SFX"
		sfxGroup.Volume = SoundConfig.DefaultSFXVolume or 1.0
		sfxGroup.Parent = masterGroup
	end

	musicGroup = masterGroup:FindFirstChild("Music") :: SoundGroup
	if not musicGroup then
		musicGroup = Instance.new("SoundGroup")
		musicGroup.Name = "Music"
		musicGroup.Volume = SoundConfig.DefaultMusicVolume or 0.5
		musicGroup.Parent = masterGroup
	end
end

-- Helper to resolve sound instance or Asset ID from physical ReplicatedStorage.Audio folder, SoundConfig, or string key
local function resolveSoundIdAndVolume(soundInput: any): (string?, number, number, string)
	if typeof(soundInput) == "Instance" and soundInput:IsA("Sound") then
		return soundInput.SoundId, soundInput.Volume, soundInput.PlaybackSpeed, SoundConfig.Categories.SFX
	elseif typeof(soundInput) == "string" then
		-- 1. Check physical ReplicatedStorage.Audio folder for designer-placed Sound instances
		local audioFolder = ReplicatedStorage:FindFirstChild("Audio")
		if audioFolder then
			local soundTemplate = audioFolder:FindFirstChild(soundInput, true)
			if soundTemplate and soundTemplate:IsA("Sound") then
				local musicSubFolder = audioFolder:FindFirstChild("Music")
				local category = (musicSubFolder and soundTemplate:IsDescendantOf(musicSubFolder)) and SoundConfig.Categories.Music or SoundConfig.Categories.SFX
				return soundTemplate.SoundId, soundTemplate.Volume, soundTemplate.PlaybackSpeed, category
			end
		end

		-- 2. Check SoundConfig registry fallback
		local def = SoundConfig.Sounds[soundInput]
		if def then
			return def.Id, def.Volume, def.Pitch or 1.0, SoundConfig.Categories.SFX
		end

		-- 3. Format raw asset ID or URL
		if string.match(soundInput, "^rbxassetid://") or string.match(soundInput, "^http") then
			return soundInput, 0.5, 1.0, SoundConfig.Categories.SFX
		elseif string.match(soundInput, "^%d+$") then
			return "rbxassetid://" .. soundInput, 0.5, 1.0, SoundConfig.Categories.SFX
		end
	end

	return nil, 0.5, 1.0, SoundConfig.Categories.SFX
end

-- Plays a 2D or 3D one-shot sound effect routed through SoundGroup channels
function GameplayAudio.playOneShot(
	soundInput: any,
	parent: Instance?,
	volumeOverride: number?,
	pitchOverride: number?
): Sound?
	if soundInput == nil then
		log("playOneShot failed: soundInput is nil")
		return nil
	end

	local soundId, defaultVol, defaultPitch, category = resolveSoundIdAndVolume(soundInput)
	if not soundId then
		log("playOneShot failed: Could not resolve soundId for input:", tostring(soundInput))
		return nil
	end

	if not sfxGroup then
		GameplayAudio.initSoundGroups()
	end

	local sound = Instance.new("Sound")
	sound.Name = "GameplayAudio_OneShot"
	sound.SoundId = soundId
	sound.Volume = volumeOverride or defaultVol
	sound.PlaybackSpeed = pitchOverride or defaultPitch
	sound.SoundGroup = if category == SoundConfig.Categories.Music then musicGroup else sfxGroup
	sound.Parent = parent or SoundService

	sound:Play()
	log(string.format("playOneShot played: '%s' | ID: %s | Volume: %.2f | Group: %s | Parent: %s", tostring(soundInput), soundId, sound.Volume, sound.SoundGroup and sound.SoundGroup.Name or "None", sound.Parent and sound.Parent.Name or "None"))

	local duration = sound.TimeLength > 0 and sound.TimeLength + 0.5 or 10
	Debris:AddItem(sound, duration)

	return sound
end

-- Plays a coin pickup sound with dynamic combo pitch scaling (1.0 -> 1.5)
function GameplayAudio.playPickupCombo(parent: Instance?): Sound?
	local now = os.clock()
	if (now - lastPickupTime) > COMBO_WINDOW_SECONDS then
		comboCount = 0
	end

	comboCount += 1
	lastPickupTime = now

	local calculatedPitch = math.min(MAX_PITCH, 1.0 + ((comboCount - 1) * PITCH_STEP))
	return GameplayAudio.playOneShot("CoinPickup", parent, nil, calculatedPitch)
end

-- Plays a looped sound tracked by a unique string ID
function GameplayAudio.playLooped(
	loopId: string,
	soundInput: any,
	parent: Instance?,
	volumeOverride: number?,
	pitchOverride: number?
): Sound?
	if activeLoops[loopId] then return activeLoops[loopId] end

	local soundId, defaultVol, defaultPitch, category = resolveSoundIdAndVolume(soundInput)
	if not soundId then return nil end

	if not sfxGroup then GameplayAudio.initSoundGroups() end

	local sound = Instance.new("Sound")
	sound.Name = "GameplayAudio_Loop_" .. loopId
	sound.SoundId = soundId
	sound.Looped = true
	sound.Volume = volumeOverride or defaultVol
	sound.PlaybackSpeed = pitchOverride or defaultPitch
	sound.SoundGroup = if category == SoundConfig.Categories.Music then musicGroup else sfxGroup
	sound.Parent = parent or SoundService

	sound:Play()
	activeLoops[loopId] = sound

	return sound
end

-- Stops and destroys a tracked looped sound by its unique ID
function GameplayAudio.stopLooped(loopId: string, fadeOutTime: number?)
	local soundInstance = activeLoops[loopId]
	if not soundInstance then return end

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

-- Check if loop is active
function GameplayAudio.isLoopActive(loopId: string): boolean
	return activeLoops[loopId] ~= nil
end

-- BGM Playlist Management
function GameplayAudio.startMusicPlaylist()
	if isPlaylistActive then return end
	isPlaylistActive = true

	if not musicGroup then GameplayAudio.initSoundGroups() end

	-- Check for designer-placed Music Sound instances in ReplicatedStorage.Audio.Music
	local audioFolder = ReplicatedStorage:FindFirstChild("Audio")
	local musicFolder = audioFolder and audioFolder:FindFirstChild("Music")
	local musicSounds = {}

	if musicFolder then
		for _, child in ipairs(musicFolder:GetChildren()) do
			if child:IsA("Sound") then
				table.insert(musicSounds, { Name = child.Name, Id = child.SoundId, Volume = child.Volume })
			end
		end
	end

	local playlist = #musicSounds > 0 and musicSounds or SoundConfig.DefaultPlaylist
	if not playlist or #playlist == 0 then return end

	local function playTrack(index: number)
		if not isPlaylistActive then return end

		local trackData = playlist[index]
		if not trackData then return end

		local bgm = Instance.new("Sound")
		bgm.Name = "BGM_" .. trackData.Name
		bgm.SoundId = trackData.Id
		bgm.Volume = trackData.Volume or 0.3
		bgm.SoundGroup = musicGroup
		bgm.Parent = SoundService

		currentBgmTrack = bgm
		bgm:Play()

		bgm.Ended:Connect(function()
			bgm:Destroy()
			if isPlaylistActive then
				currentPlaylistIndex = (currentPlaylistIndex % #playlist) + 1
				playTrack(currentPlaylistIndex)
			end
		end)
	end

	playTrack(currentPlaylistIndex)
end

function GameplayAudio.stopMusicPlaylist()
	isPlaylistActive = false
	if currentBgmTrack then
		currentBgmTrack:Stop()
		currentBgmTrack:Destroy()
		currentBgmTrack = nil
	end
end

return GameplayAudio
