--!nonstrict
--[[
    MovementMotor.luau
    Reusable, object-oriented physics motor wrapper managing LinearVelocity, Attachment, VectorForce, and AlignOrientation.
    Ported from Roblox AI Workspace pattern.
    Location: src/shared/Utils/MovementMotor.luau (Syncs to ReplicatedStorage.Shared.Utils.MovementMotor)
--]]

local Workspace = game:GetService("Workspace")

local MovementMotor = {}
MovementMotor.__index = MovementMotor

export type Config = {
	attachmentName: string,
	linearVelocityName: string,
	gravityForceName: string?,
	orientationName: string?,
	orientationResponsiveness: number?,
	orientationMaxAngularVelocity: number?,
	orientationMaxTorque: number?,
}

export type MovementMotorInstance = typeof(setmetatable({} :: {
	_config: Config,
	originalAutoRotate: boolean?,
	attachment: Attachment?,
	linearVelocity: LinearVelocity?,
	gravityForce: VectorForce?,
	orientation: AlignOrientation?,
	rootPart: BasePart?,
}, MovementMotor))

function MovementMotor.new(config: Config): MovementMotorInstance
	return setmetatable({
		_config = config,
		originalAutoRotate = nil,
		attachment = nil,
		linearVelocity = nil,
		gravityForce = nil,
		orientation = nil,
		rootPart = nil,
	}, MovementMotor) :: MovementMotorInstance
end

function MovementMotor:destroy()
	for _, instance in pairs({
		self.linearVelocity,
		self.gravityForce,
		self.orientation,
		self.attachment,
	}) do
		if instance ~= nil then
			instance:Destroy()
		end
	end

	self.attachment = nil
	self.linearVelocity = nil
	self.gravityForce = nil
	self.orientation = nil
	self.rootPart = nil
end

function MovementMotor:ensure(rootPart: BasePart)
	if self.rootPart ~= nil and self.rootPart ~= rootPart then
		self:destroy()
	end

	local needsGravityForce = self._config.gravityForceName ~= nil
	local needsOrientation = self._config.orientationName ~= nil
	if
		self.attachment ~= nil
		and self.linearVelocity ~= nil
		and (not needsGravityForce or self.gravityForce ~= nil)
		and (not needsOrientation or self.orientation ~= nil)
	then
		return
	end

	if self.attachment ~= nil or self.linearVelocity ~= nil or self.gravityForce ~= nil or self.orientation ~= nil then
		self:destroy()
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = self._config.attachmentName
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = self._config.linearVelocityName
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linearVelocity.ForceLimitsEnabled = true
	linearVelocity.MaxForce = 100000
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.Parent = rootPart

	self.attachment = attachment
	self.linearVelocity = linearVelocity
	self.rootPart = rootPart

	if self._config.orientationName ~= nil then
		local orientation = Instance.new("AlignOrientation")
		orientation.Name = self._config.orientationName
		orientation.Attachment0 = attachment
		orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		orientation.AlignType = Enum.AlignType.AllAxes
		orientation.ReactionTorqueEnabled = false
		orientation.RigidityEnabled = false
		orientation.Responsiveness = self._config.orientationResponsiveness or 15
		orientation.MaxAngularVelocity = self._config.orientationMaxAngularVelocity or math.huge
		orientation.MaxTorque = self._config.orientationMaxTorque or math.huge
		orientation.CFrame = rootPart.CFrame.Rotation
		orientation.Parent = rootPart

		self.orientation = orientation
	else
		self.orientation = nil
	end

	if self._config.gravityForceName ~= nil then
		local gravityForce = Instance.new("VectorForce")
		gravityForce.Name = self._config.gravityForceName
		gravityForce.Attachment0 = attachment
		gravityForce.RelativeTo = Enum.ActuatorRelativeTo.World
		gravityForce.ApplyAtCenterOfMass = true
		gravityForce.Force = Vector3.zero
		gravityForce.Parent = rootPart

		self.gravityForce = gravityForce
	else
		self.gravityForce = nil
	end
end

function MovementMotor:capture(humanoid: Humanoid)
	self.originalAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false
end

function MovementMotor:release(humanoid: Humanoid?)
	if humanoid ~= nil and self.originalAutoRotate ~= nil then
		humanoid.AutoRotate = self.originalAutoRotate
	end
	self.originalAutoRotate = nil
end

function MovementMotor:zeroAngularVelocity(rootPart: BasePart)
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

return MovementMotor
