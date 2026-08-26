--!nonstrict
--[[
    RagdollModule.luau
    Handles 2.5-second physics ragdoll state transitions with BallSocketConstraint joints and NoCollisionConstraint limb solvers.
    Location: src/shared/Utils/RagdollModule.luau (Syncs to ReplicatedStorage.Shared.Utils.RagdollModule)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger"))

local log = Logger.create("Ragdoll")
local RagdollModule = {}

-- Create BallSocketConstraint & NoCollisionConstraint replacements for a Motor6D joint
local function createRagdollJoint(motor: Instance)
	local part0 = (motor :: Motor6D).Part0
	local part1 = (motor :: Motor6D).Part1
	if not part0 or not part1 then return nil, nil, nil, nil end

	local att0 = Instance.new("Attachment")
	att0.Name = "RagdollAttachment0_" .. motor.Name
	att0.CFrame = (motor :: Motor6D).C0
	att0.Parent = part0

	local att1 = Instance.new("Attachment")
	att1.Name = "RagdollAttachment1_" .. motor.Name
	att1.CFrame = (motor :: Motor6D).C1
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

	-- NoCollisionConstraint to prevent physics solver spasms between connected limb parts
	local noCollide = Instance.new("NoCollisionConstraint")
	noCollide.Name = "RagdollNoCollide_" .. motor.Name
	noCollide.Part0 = part0
	noCollide.Part1 = part1
	noCollide.Parent = part1

	return ballSocket, att0, att1, noCollide
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
	log(string.format("Triggering ragdoll state for %s (Duration: %.1fs)", player.Name, ragdollTime))

	-- Set Humanoid to Physics state & PlatformStand
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	local disabledMotors = {}
	local createdSockets = {}
	local createdAttachments = {}
	local createdNoCollides = {}
	local originalCollisions = {}

	-- Enable CanCollide = true on character body parts so they tumble cleanly on the floor
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			originalCollisions[part] = part.CanCollide
			part.CanCollide = true
		end
	end

	-- Convert all Motor6D joints into physical BallSocketConstraints + NoCollisionConstraints
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			local socket, att0, att1, noCollide = createRagdollJoint(descendant)
			if socket and att0 and att1 and noCollide then
				descendant.Enabled = false
				table.insert(disabledMotors, descendant)
				table.insert(createdSockets, socket)
				table.insert(createdAttachments, att0)
				table.insert(createdAttachments, att1)
				table.insert(createdNoCollides, noCollide)
			end
		end
	end

	-- Recovery Timer (2.5 seconds)
	task.delay(ragdollTime, function()
		if character and humanoid and humanoid.Parent then
			-- Destroy ragdoll socket & no-collision constraints
			for _, socket in ipairs(createdSockets) do
				if socket and socket.Parent then socket:Destroy() end
			end
			for _, att in ipairs(createdAttachments) do
				if att and att.Parent then att:Destroy() end
			end
			for _, nc in ipairs(createdNoCollides) do
				if nc and nc.Parent then nc:Destroy() end
			end

			-- Re-enable Motor6D joints
			for _, motor in ipairs(disabledMotors) do
				if motor and motor.Parent then
					motor.Enabled = true
				end
			end

			-- Restore original CanCollide settings
			for part, canCollide in pairs(originalCollisions) do
				if part and part.Parent then
					part.CanCollide = canCollide
				end
			end

			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			PlayerFSM.SetState(player, "Normal")
			log(string.format("%s recovered from physical ragdoll state.", player.Name))
		end
	end)

	return true
end

return RagdollModule
