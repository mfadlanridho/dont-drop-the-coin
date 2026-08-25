--!nonstrict
--[[
    RagdollModule.luau
    Handles 2.5-second physics ragdoll state transitions for character humanoid.
    Location: src/server/Services/RagdollModule.luau (Syncs to ServerScriptService.Server.Services.RagdollModule)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))

local RagdollModule = {}

-- Trigger Ragdoll State on Character
function RagdollModule.TriggerRagdoll(player: Player, duration: number?): boolean
	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not humanoid or not hrp then return false end

	-- Enforce FSM state transition
	local transitionSuccess = PlayerFSM.SetState(player, "Ragdolled")
	if not transitionSuccess then return false end

	local ragdollTime = duration or Config.RAGDOLL_DURATION

	-- Set Humanoid PlatformStand
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	-- Temporarily disable Motor6Ds to allow physical joint ragdolling
	local disabledMotors = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Name ~= "RootJoint" then
			descendant.Enabled = false
			table.insert(disabledMotors, descendant)
		end
	end

	-- Recovery Timer
	task.delay(ragdollTime, function()
		if character and humanoid and humanoid.Parent then
			-- Re-enable Motor6Ds
			for _, motor in ipairs(disabledMotors) do
				if motor and motor.Parent then
					motor.Enabled = true
				end
			end
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			PlayerFSM.SetState(player, "Normal")
			print(string.format("[RagdollModule] %s recovered from ragdoll state.", player.Name))
		end
	end)

	return true
end

return RagdollModule
