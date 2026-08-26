--!strict
--[[
    AudioController.client.luau
    Client-side listener for server audio events and UI sound feedback.
    Location: src/client/Controllers/AudioController.client.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local GameplayAudio = require(Shared:WaitForChild("Utils"):WaitForChild("GameplayAudio") :: ModuleScript)

local PlaySoundRemote = Remotes.Get("PlaySound")

-- Listen to server triggers: PlaySound:FireClient(player, soundKey, parentPart?, volumeOverride?, pitchOverride?)
PlaySoundRemote.OnClientEvent:Connect(function(
	soundInput: any,
	parent: Instance?,
	volumeOverride: number?,
	pitchOverride: number?
)
	GameplayAudio.playOneShot(soundInput, parent, volumeOverride, pitchOverride)
end)

local AudioController = {}

-- Utility to easily play UI sound on client
function AudioController.playUI(soundKey: string, volumeOverride: number?, pitchOverride: number?)
	GameplayAudio.playOneShot(soundKey, nil, volumeOverride, pitchOverride)
end

return AudioController
