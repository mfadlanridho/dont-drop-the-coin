local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conveyor = require(
	ReplicatedStorage.Shared.Conveyor
)

local folder = workspace:WaitForChild("Hazards"):WaitForChild("Conveyors")

local conveyors = {}

local function setup(part)
	if not part:IsA("BasePart") then
		return
	end

	if conveyors[part] then
		return
	end

	local speed = part:GetAttribute("Speed")

	if typeof(speed) ~= "number" then
		speed = 12
	end

	conveyors[part] = Conveyor.new(part, {
		Speed = speed
	})
end

local function cleanup(part)
	local conveyor = conveyors[part]

	if conveyor then
		conveyor:Destroy()
		conveyors[part] = nil
	end
end

for _, part in folder:GetChildren() do
	setup(part)
end

folder.ChildAdded:Connect(setup)
folder.ChildRemoved:Connect(cleanup)