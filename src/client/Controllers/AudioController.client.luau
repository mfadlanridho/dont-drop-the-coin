--!strict
--[[
    AudioController.client.luau
    Client-side listener for server audio events, pitch combo triggers, BGM playlist start, and UI sound feedback.
    Location: src/client/Controllers/AudioController.client.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local GameplayAudio = require(Shared:WaitForChild("Utils"):WaitForChild("GameplayAudio") :: ModuleScript)
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)

local log = Logger.create("Audio")

local PlaySoundRemote = Remotes.Get("PlaySound")

-- Initialize SoundGroup channels on client load
GameplayAudio.initSoundGroups()

-- Listen to server triggers: PlaySound:FireClient(player, soundKey, parentPart?, volumeOverride?, pitchOverride?)
PlaySoundRemote.OnClientEvent:Connect(function(
	soundInput: any,
	parent: Instance?,
	volumeOverride: number?,
	pitchOverride: number?
)
	log("PlaySound remote received on client:", tostring(soundInput), "Parent:", parent and parent:GetFullName() or "nil")
	if soundInput == "CoinPickupCombo" then
		GameplayAudio.playPickupCombo(parent)
	else
		GameplayAudio.playOneShot(soundInput, parent, volumeOverride, pitchOverride)
	end
end)

local AudioController = {}

-- Utility to easily play UI sound on client
function AudioController.playUI(soundKey: string, volumeOverride: number?, pitchOverride: number?)
	GameplayAudio.playOneShot(soundKey, nil, volumeOverride, pitchOverride)
end

-- Utility to play pickup combo sound on client
function AudioController.playPickupCombo(parent: Instance?)
	GameplayAudio.playPickupCombo(parent)
end

return AudioController
