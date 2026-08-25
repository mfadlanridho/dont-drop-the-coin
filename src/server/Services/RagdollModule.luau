--!nonstrict
--[[
    RagdollModule.luau
    Handles 2.5-second physics ragdoll state transitions with BallSocketConstraint joints for physical limb flopping.
    Location: src/server/Services/RagdollModule.luau (Syncs to ServerScriptService.Server.Services.RagdollModule)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))

local RagdollModule = {}

-- Create BallSocketConstraint replacement for a Motor6D joint
local function createRagdollJoint(motor: Motor6D): (BallSocketConstraint, Attachment, Attachment)?
	local part0 = motor.Part0
	local part1 = motor.Part1
	if not part0 or not part1 then return nil end

	local att0 = Instance.new("Attachment")
	att0.Name = "RagdollAttachment0_" .. motor.Name
	att0.CFrame = motor.C0
	att0.Parent = part0

	local att1 = Instance.new("Attachment")
	att1.Name = "RagdollAttachment1_" .. motor.Name
	att1.CFrame = motor.C1
	att1.Parent = part1

	local ballSocket = Instance.new("BallSocketConstraint")
	ballSocket.Name = "RagdollSocket_" .. motor.Name
	ballSocket.Attachment0 = att0
	ballSocket.Attachment1 = att1
	ballSocket.LimitsEnabled = true
	ballSocket.UpperAngle = 60
	ballSocket.TwistLimitsEnabled = true
	ballSocket.TwistLowerAngle = -45
	ballSocket.TwistUpperAngle = 45
	ballSocket.Parent = part1

	return ballSocket, att0, att1
end

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

	-- Set Humanoid to Physics state & PlatformStand
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	local disabledMotors = {}
	local createdSockets = {}
	local createdAttachments = {}

	-- Convert Motor6D joints into physical BallSocketConstraint ragdoll joints
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Name ~= "RootJoint" then
			local socket, att0, att1 = createRagdollJoint(descendant)
			if socket and att0 and att1 then
				descendant.Enabled = false
				table.insert(disabledMotors, descendant)
				table.insert(createdSockets, socket)
				table.insert(createdAttachments, att0)
				table.insert(createdAttachments, att1)
			end
		end
	end

	-- Recovery Timer
	task.delay(ragdollTime, function()
		if character and humanoid and humanoid.Parent then
			-- Destroy ragdoll socket constraints
			for _, socket in ipairs(createdSockets) do
				if socket and socket.Parent then socket:Destroy() end
			end
			for _, att in ipairs(createdAttachments) do
				if att and att.Parent then att:Destroy() end
			end

			-- Re-enable Motor6D joints
			for _, motor in ipairs(disabledMotors) do
				if motor and motor.Parent then
					motor.Enabled = true
				end
			end

			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			PlayerFSM.SetState(player, "Normal")
			print(string.format("[RagdollModule] %s recovered from physical ragdoll state.", player.Name))
		end
	end)

	return true
end

return RagdollModule
