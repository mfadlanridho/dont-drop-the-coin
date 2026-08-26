--!strict
--[[
    MusicController.client.luau
    Client background music player with queue management and crossfading transitions.
    Location: src/client/Controllers/MusicController.client.luau
--]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundConfig = require(Shared:WaitForChild("Config"):WaitForChild("SoundConfig") :: ModuleScript)

local currentSound: Sound? = nil
local currentBaseVolume = SoundConfig.DefaultMusicVolume
local volumeMultiplier = 1.0
local isMuted = false

local songQueue: { { Name: string, Id: string, Volume: number } } = {}
local currentConnection: RBXScriptConnection? = nil

-- Listen for settings changes (BindableEvent in ReplicatedStorage)
local musicVolumeEvent = ReplicatedStorage:FindFirstChild("MusicVolumeChanged") :: BindableEvent?
if not musicVolumeEvent then
	musicVolumeEvent = Instance.new("BindableEvent")
	musicVolumeEvent.Name = "MusicVolumeChanged"
	musicVolumeEvent.Parent = ReplicatedStorage
end

musicVolumeEvent.Event:Connect(function(newMultiplier: number, muted: boolean?)
	volumeMultiplier = math.clamp(newMultiplier, 0, 1)
	if muted ~= nil then
		isMuted = muted
	end

	if currentSound then
		currentSound.Volume = isMuted and 0 or (currentBaseVolume * volumeMultiplier)
	end
end)

-- Helper to shuffle playlist queue
local function shufflePlaylist(t: { any })
	local shuffled = table.clone(t)
	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

local playNextTrack: () -> ()

local function playTrack(trackData: { Name: string, Id: string, Volume: number })
	currentBaseVolume = trackData.Volume or SoundConfig.DefaultMusicVolume

	local newSound = Instance.new("Sound")
	newSound.Name = "MusicTrack_" .. trackData.Name
	newSound.SoundId = trackData.Id
	newSound.Volume = 0
	newSound.Looped = false
	newSound.Parent = SoundService
	newSound:Play()

	local targetVolume = isMuted and 0 or (currentBaseVolume * volumeMultiplier)

	-- Fade in new song
	local fadeInTween = TweenService:Create(
		newSound,
		TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = targetVolume }
	)
	fadeInTween:Play()

	-- Fade out & destroy previous song
	if currentSound then
		local oldSound = currentSound
		if currentConnection then
			currentConnection:Disconnect()
			currentConnection = nil
		end

		local fadeOutTween = TweenService:Create(
			oldSound,
			TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Volume = 0 }
		)
		fadeOutTween:Play()
		fadeOutTween.Completed:Connect(function()
			oldSound:Stop()
			oldSound:Destroy()
		end)
	end

	currentSound = newSound

	-- Next track when ended
	local connection: RBXScriptConnection? = nil
	connection = newSound.Ended:Connect(function()
		if connection then
			connection:Disconnect()
		end
		if currentConnection == connection then
			currentConnection = nil
		end
		playNextTrack()
	end)
	currentConnection = connection
end

playNextTrack = function()
	local playlist = SoundConfig.DefaultPlaylist
	if #playlist == 0 then
		return
	end

	if #playlist == 1 then
		if not currentSound then
			playTrack(playlist[1])
		end
		return
	end

	if #songQueue == 0 then
		songQueue = shufflePlaylist(playlist)
		if currentSound and songQueue[1].Name == string.gsub(currentSound.Name, "^MusicTrack_", "") then
			local temp = songQueue[1]
			songQueue[1] = songQueue[2]
			songQueue[2] = temp
		end
	end

	local nextTrack = table.remove(songQueue, 1)
	if nextTrack then
		playTrack(nextTrack)
	end
end

-- Wait startup delay for game load before starting music
task.delay(2, function()
	playNextTrack()
end)
