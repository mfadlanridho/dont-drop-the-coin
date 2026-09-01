--!strict
--[[
    AudioController.client.luau
    Unified client audio controller for server sound events, pitch combo triggers, BGM playlist queue management, and UI audio feedback.
    100% integrated with ReplicatedStorage.Packages.AudioModule submodule.
    Location: src/client/Controllers/AudioController.client.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared:WaitForChild("Config"):WaitForChild("SoundConfig") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local Packages = ReplicatedStorage:WaitForChild("Packages")

local AudioModule = require(Packages:WaitForChild("AudioModule") :: ModuleScript)
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

local log = Logger.create("Audio")

-- Server SFX Remote Event Listener
local PlaySoundRemote = Remotes.Get("PlaySound")
if PlaySoundRemote then
	PlaySoundRemote.OnClientEvent:Connect(function(
		soundInput: any,
		parent: Instance?,
		volumeOverride: number?,
		pitchOverride: number?
	)
		log("PlaySound remote received on client:", tostring(soundInput), "Parent:", parent and parent:GetFullName() or "nil")
		if soundInput == "CoinPickupCombo" then
			AudioModule.playPickupCombo("CoinPickup", parent)
		else
			AudioModule.playOneShot(soundInput, {
				parent = parent,
				volume = volumeOverride,
				pitch = pitchOverride,
			})
		end
	end)
end

-- Music Settings BindableEvent
local musicVolumeEvent = ReplicatedStorage:FindFirstChild("MusicVolumeChanged") :: BindableEvent?
if not musicVolumeEvent then
	musicVolumeEvent = Instance.new("BindableEvent")
	musicVolumeEvent.Name = "MusicVolumeChanged"
	musicVolumeEvent.Parent = ReplicatedStorage
end

musicVolumeEvent.Event:Connect(function(newMultiplier: number, muted: boolean?)
	local volume = math.clamp(newMultiplier, 0, 1)
	if muted then
		volume = 0
	end
	AudioModule.setVolume("Music", volume)
end)

-- Playlist Queue State
local songQueue: { { Name: string, Id: string, Volume: number } } = {}
local currentTrackName: string? = nil

local function shufflePlaylist(t: { any })
	local shuffled = table.clone(t)
	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

local function playNextTrack()
	local playlist = SoundConfig.DefaultPlaylist
	if not playlist or #playlist == 0 then
		return
	end

	if #songQueue == 0 then
		songQueue = shufflePlaylist(playlist)
		if currentTrackName and songQueue[1].Name == currentTrackName and #songQueue > 1 then
			local temp = songQueue[1]
			songQueue[1] = songQueue[2]
			songQueue[2] = temp
		end
	end

	local nextTrack = table.remove(songQueue, 1)
	if nextTrack then
		currentTrackName = nextTrack.Name
		log("🎵 Starting BGM playlist track via AudioModule:", nextTrack.Name)
		AudioModule.playBGM(nextTrack.Id, 2.0)
	end
end

local AudioController = {}

function AudioController.Init()
	-- Preload Default Playlist
	local playlistAssetIds = {}
	for _, track in ipairs(SoundConfig.DefaultPlaylist or {}) do
		table.insert(playlistAssetIds, track.Id)
	end
	AudioModule.preloadSounds(playlistAssetIds)

	-- Start BGM Playlist after 2 seconds startup delay
	task.delay(2, function()
		playNextTrack()
	end)

	print("[AudioController] Unified client audio controller initialized successfully with AudioModule integration!")
end

-- Utility to easily play UI sound on client
function AudioController.playUI(soundKey: string, volumeOverride: number?, pitchOverride: number?)
	AudioModule.playOneShot(soundKey, {
		category = "UI",
		volume = volumeOverride,
		pitch = pitchOverride,
	})
end

-- Utility to play pickup combo sound on client
function AudioController.playPickupCombo(parent: Instance?)
	AudioModule.playPickupCombo("CoinPickup", parent)
end

return AudioController
