--!nonstrict
--[[
    RotatingPlatform.luau
    Modular OOP component for circular rotating platform hazards (e.g. Zone 2 RP_* parts).
    Uses a HingeConstraint in Motor mode to provide continuous, smooth physics rotation,
    ensuring players standing on the platform rotate naturally with tangential friction.
    Location: src/server/Hazards/RotatingPlatform.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

local log = Logger.create("Hazards")

local RotatingPlatform = {}
RotatingPlatform.__index = RotatingPlatform

export type RotatingPlatformInstance = {
	socket: BasePart,
	folder: Instance,
	hubPart: BasePart,
	movingParts: { BasePart },
	hinge: HingeConstraint,
	motorAttachment0: Attachment,
	motorAttachment1: Attachment,
	speed: number,
	isDestroyed: boolean,
	destroy: (self: RotatingPlatformInstance) -> (),
}

function RotatingPlatform.new(socket: BasePart, modelOrFolder: Instance): RotatingPlatformInstance?
	-- Find or identify the central hub part
	local hubPart: BasePart? = modelOrFolder:FindFirstChild("RP_Hub") :: any
	if not hubPart then
		-- Fallback: locate a part closest to the socket
		for _, child in ipairs(modelOrFolder:GetChildren()) do
			if child:IsA("BasePart") and child.Name:match("Hub") then
				hubPart = child
				break
			end
		end
	end

	if not hubPart then
		warn(string.format("[RotatingPlatform] No Hub part found in %s for socket %s", modelOrFolder.Name, socket.Name))
		return nil
	end

	local self = setmetatable({}, RotatingPlatform) :: any
	self.socket = socket
	self.folder = modelOrFolder
	self.hubPart = hubPart
	self.movingParts = {}
	self.isDestroyed = false

	-- Read speed configuration from socket attributes or default
	local targetSpeed = socket:GetAttribute("Speed")
	self.speed = typeof(targetSpeed) == "number" and targetSpeed or 1.5 -- Angular velocity in rad/s

	-- Hub part stays firmly anchored as the static base
	hubPart.Anchored = true
	hubPart.CanCollide = true

	-- Collect all rotating pieces (RP_Disc, RP_Body, RP_Ring, etc.)
	local discPart: BasePart? = modelOrFolder:FindFirstChild("RP_Disc") :: any
	for _, child in ipairs(modelOrFolder:GetChildren()) do
		if child:IsA("BasePart") and child ~= hubPart and child.Name:match("^RP_") then
			table.insert(self.movingParts, child)
			if not discPart then
				discPart = child
			end
		end
	end

	if not discPart then
		warn(string.format("[RotatingPlatform] No rotating parts found for %s", socket.Name))
		return nil
	end

	local socketPos = socket.Position

	-- World axis: use the vertical world Y up vector for standard horizontal platform rotation
	local worldAxis = Vector3.new(0, 1, 0)

	local att0 = Instance.new("Attachment")
	att0.Name = "RotatingPlatform_Att0"
	att0.Parent = hubPart
	att0.WorldCFrame = socket.CFrame
	att0.WorldAxis = worldAxis

	local att1 = Instance.new("Attachment")
	att1.Name = "RotatingPlatform_Att1"
	att1.Parent = discPart
	att1.WorldCFrame = socket.CFrame
	att1.WorldAxis = worldAxis

	-- Weld all moving parts to discPart so they rotate together as a rigid assembly
	for _, part in ipairs(self.movingParts) do
		if part ~= discPart then
			part.Anchored = false
			part.CanCollide = true
			part.Massless = false

			local weld = Instance.new("WeldConstraint")
			weld.Name = "RP_Weld_" .. part.Name
			weld.Part0 = discPart
			weld.Part1 = part
			weld.Parent = discPart
		end
	end

	-- Unanchor discPart so it can be driven by the constraint
	discPart.Anchored = false
	discPart.CanCollide = true

	-- Create motorized HingeConstraint
	local hinge = Instance.new("HingeConstraint")
	hinge.Name = "RotatingPlatform_Hinge"
	hinge.Attachment0 = att0
	hinge.Attachment1 = att1
	hinge.ActuatorType = Enum.ActuatorType.Motor
	hinge.MotorMaxTorque = 100000000
	hinge.AngularVelocity = self.speed
	hinge.Parent = discPart

	self.hinge = hinge
	self.motorAttachment0 = att0
	self.motorAttachment1 = att1

	log(string.format("[RotatingPlatform] Successfully initialized for socket %s with speed %.2f", socket.Name, self.speed))
	return self
end

function RotatingPlatform:destroy()
	if self.isDestroyed then return end
	self.isDestroyed = true

	if self.hinge then
		self.hinge:Destroy()
	end
	if self.motorAttachment0 then
		self.motorAttachment0:Destroy()
	end
	if self.motorAttachment1 then
		self.motorAttachment1:Destroy()
	end

	for _, part in ipairs(self.movingParts) do
		if part and part.Parent then
			part.Anchored = true
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("WeldConstraint") and child.Name:match("^RP_Weld") then
					child:Destroy()
				end
			end
		end
	end
end

return RotatingPlatform
