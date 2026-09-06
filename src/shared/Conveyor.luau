local RunService = game:GetService("RunService")

local Conveyor = {}
Conveyor.__index = Conveyor

function Conveyor.new(part, settings)
	assert(part and part:IsA("BasePart"), "[Conveyor] Invalid BasePart")

	settings = settings or {}

	local self = setmetatable({}, Conveyor)

	self.Part = part
	self.Speed = settings.Speed or 12
	self.Enabled = true

	self.Connection = RunService.Heartbeat:Connect(function()
		self:Update()
	end)

	print("[Conveyor] Started:", part:GetFullName(), "Speed:", self.Speed)

	return self
end

function Conveyor:Update()
	if not self.Enabled or not self.Part or not self.Part.Parent then
		return
	end

	local direction = self.Part.CFrame.LookVector

	self.Part.AssemblyLinearVelocity = direction * self.Speed
end

function Conveyor:SetSpeed(speed)
	assert(typeof(speed) == "number", "[Conveyor] Speed must be a number")
	self.Speed = speed
end

function Conveyor:SetEnabled(enabled)
	assert(typeof(enabled) == "boolean", "[Conveyor] Enabled must be a boolean")
	self.Enabled = enabled

	if not enabled and self.Part then
		self.Part.AssemblyLinearVelocity = Vector3.zero
	end
end

function Conveyor:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	if self.Part then
		self.Part.AssemblyLinearVelocity = Vector3.zero
	end

	self.Part = nil
end

return Conveyor