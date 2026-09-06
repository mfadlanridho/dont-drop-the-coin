local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Conveyor = {}
Conveyor.__index = Conveyor

function Conveyor.new(part, settings)
	assert(part and part:IsA("BasePart"), "[Conveyor] Invalid conveyor part")

	settings = settings or {}

	local self = setmetatable({}, Conveyor)

	self.Part = part
	self.Speed = settings.Speed or 12
	self.Enabled = true
	self.Debug = settings.Debug ~= false
	self.Connection = nil
	self.Constraints = {}

	part.CanCollide = true
	part.CanTouch = true

	if self.Debug then
		print(
			"[Conveyor] Started:",
			part:GetFullName(),
			"Speed:",
			self.Speed,
			"Direction:",
			part.CFrame.LookVector
		)
	end

	self.Connection = RunService.Heartbeat:Connect(function()
		self:Update()
	end)

	return self
end

function Conveyor:Update()
	if not self.Enabled or not self.Part or not self.Part.Parent then
		return
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {self.Part}

	local detectionSize = Vector3.new(
		self.Part.Size.X,
		2.5,
		self.Part.Size.Z
	)

	local detectionCFrame = self.Part.CFrame + Vector3.new(0, 1.25, 0)

	local parts = workspace:GetPartBoundsInBox(
		detectionCFrame,
		detectionSize,
		overlapParams
	)

	local characters = {}

	for _, touchingPart in parts do
		local character = touchingPart:FindFirstAncestorOfClass("Model")

		if character and not characters[character] then
			characters[character] = true

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoid and rootPart and humanoid.Health > 0 then
				local player = Players:GetPlayerFromCharacter(character)

				if player and self:IsStandingOnConveyor(character, rootPart) then
					self:ApplyConveyor(rootPart)

					if self.Debug then
						print("[Conveyor] Moving:", player.Name)
					end
				end
			end
		end
	end

	self:CleanupInactiveConstraints(characters)
end

function Conveyor:IsStandingOnConveyor(character, rootPart)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}

	local result = workspace:Raycast(
		rootPart.Position,
		Vector3.new(0, -5, 0),
		raycastParams
	)

	return result and result.Instance == self.Part
end

function Conveyor:ApplyConveyor(rootPart)
	local constraint = self.Constraints[rootPart]

	if not constraint then
		local attachment = Instance.new("Attachment")
		attachment.Name = "ConveyorAttachment"
		attachment.Parent = rootPart

		constraint = Instance.new("LinearVelocity")
		constraint.Name = "ConveyorVelocity"
		constraint.Attachment0 = attachment
		constraint.RelativeTo = Enum.ActuatorRelativeTo.World
		constraint.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		constraint.ForceLimitsEnabled = false
		constraint.Parent = rootPart

		self.Constraints[rootPart] = {
			Velocity = constraint,
			Attachment = attachment,
			LastSeen = os.clock()
		}
	end

	local data = self.Constraints[rootPart]

	data.LastSeen = os.clock()

	local direction = self.Part.CFrame.LookVector

	data.Velocity.VectorVelocity = Vector3.new(
		direction.X * self.Speed,
		0,
		direction.Z * self.Speed
	)
end

function Conveyor:CleanupInactiveConstraints(activeCharacters)
	local now = os.clock()

	for rootPart, data in pairs(self.Constraints) do
		local character = rootPart.Parent
		local stillActive = character and activeCharacters[character]

		if not stillActive or now - data.LastSeen > 0.1 then
			if data.Velocity then
				data.Velocity:Destroy()
			end

			if data.Attachment then
				data.Attachment:Destroy()
			end

			self.Constraints[rootPart] = nil
		end
	end
end

function Conveyor:SetSpeed(speed)
	assert(
		typeof(speed) == "number",
		"[Conveyor] Speed must be a number"
	)

	self.Speed = speed
end

function Conveyor:SetEnabled(enabled)
	assert(
		typeof(enabled) == "boolean",
		"[Conveyor] Enabled must be a boolean"
	)

	self.Enabled = enabled
end

function Conveyor:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	for rootPart, data in pairs(self.Constraints) do
		if data.Velocity then
			data.Velocity:Destroy()
		end

		if data.Attachment then
			data.Attachment:Destroy()
		end

		self.Constraints[rootPart] = nil
	end

	if self.Debug and self.Part then
		print("[Conveyor] Destroyed:", self.Part:GetFullName())
	end

	self.Part = nil
end

return Conveyor