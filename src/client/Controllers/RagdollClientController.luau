--!nonstrict
--[[
    RagdollClientController.luau
    Client controller handling incoming TriggerRagdoll remote events and executing local physics knockback launch & BallSocketConstraint limb flopping.
    Location: src/client/Controllers/RagdollClientController.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local RagdollModule = require(Packages:WaitForChild("RagdollModule") :: ModuleScript)

local LocalPlayer = Players.LocalPlayer

local RagdollClientController = {}

function RagdollClientController.Init()
	local ragdollEvent = Remotes.Get("TriggerRagdoll")
	if ragdollEvent then
		ragdollEvent.OnClientEvent:Connect(function(duration: number?, launchVector: Vector3?)
			local char = LocalPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: Part
			if not hrp then return end

			-- Apply launch velocity on local client (physics owner)
			if launchVector then
				hrp.AssemblyLinearVelocity = launchVector
			end

			-- Trigger local PlatformStand physics disabler
			RagdollModule.SetPlatformStand(char, true, true)
			task.delay(duration or 2.5, function()
				if char and char.Parent then
					RagdollModule.SetPlatformStand(char, false, false)
				end
			end)
			print(string.format("[RagdollClientController] Executed local physics ragdoll & knockback launch."))
		end)
	end

	print("[RagdollClientController] Client ragdoll remote listener initialized successfully.")
end

return RagdollClientController
