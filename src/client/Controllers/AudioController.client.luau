--!strict
--[[
    AudioController.client.luau
    Client-side listener for server audio events, pitch combo triggers, BGM playlist start, and UI sound feedback.
    Uses ReplicatedStorage.Packages.AudioModule submodule directly.
    Location: src/client/Controllers/AudioController.client.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Remotes = require(Shared:WaitForChild("Remotes") :: ModuleScript)
local AudioModule = require(Packages:WaitForChild("AudioModule") :: ModuleScript)
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

local log = Logger.create("Audio")

local PlaySoundRemote = Remotes.Get("PlaySound")

-- Listen to server triggers: PlaySound:FireClient(player, soundKey, parentPart?, volumeOverride?, pitchOverride?)
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

local AudioController = {}

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
