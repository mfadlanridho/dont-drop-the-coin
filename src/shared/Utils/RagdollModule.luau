--!strict
--[[
    RagdollModule.luau
    Bridge adapter connecting project scripts to ReplicatedStorage.Packages.RagdollModule SetPlatformStand disabler.
    Location: src/shared/Utils/RagdollModule.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM") :: ModuleScript)
local PackageRagdoll = require(Packages:WaitForChild("RagdollModule") :: ModuleScript)

local RagdollModule = {}

-- Trigger Lightweight PlatformStand State on a Player (Bridges Player instance to Character model)
function RagdollModule.TriggerRagdoll(player: Player, duration: number?): boolean
	if not player or not player.Character then return false end
	local character = player.Character
	local dur = duration or 2.5

	-- Enforce Player FSM state transition
	pcall(function()
		PlayerFSM.SetState(player, "Ragdolled")
	end)

	-- Enable Lightweight PlatformStand with stopAnimations = true
	PackageRagdoll.SetPlatformStand(character, true, true)

	-- Reset Player FSM state & disable PlatformStand when duration finishes
	task.delay(dur, function()
		if character and character.Parent then
			PackageRagdoll.SetPlatformStand(character, false, false)
		end
		pcall(function()
			PlayerFSM.SetState(player, "Normal")
		end)
	end)

	return true
end

-- Direct Character Model PlatformStand Enable
function RagdollModule.SetPlatformStand(character: Model, enabled: boolean, stopAnimations: boolean?)
	PackageRagdoll.SetPlatformStand(character, enabled, stopAnimations ~= false)
end

-- Direct Character Model Ragdoll Enable
function RagdollModule.Enable(character: Model, options: any): boolean
	return PackageRagdoll.Enable(character, options)
end

-- Direct Character Model Ragdoll Disable
function RagdollModule.Disable(character: Model)
	PackageRagdoll.Disable(character)
end

-- Check if Character is Ragdolled
function RagdollModule.IsRagdolled(character: Model): boolean
	return PackageRagdoll.IsRagdolled(character)
end

return RagdollModule
