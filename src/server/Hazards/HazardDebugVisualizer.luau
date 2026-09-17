--!nonstrict
--[[
    HazardDebugVisualizer.luau
    Studio-only lightweight 3D visualizer that attaches sleek, compact badges above hazard sockets.
    Strictly gated by RunService:IsStudio() so it incurs zero overhead in production.
    Location: src/server/Hazards/HazardDebugVisualizer.luau
--]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local HazardDebugVisualizer = {}
local activeBillboards: { [Instance]: BillboardGui } = {}

-- Guard: Only run in Roblox Studio
local isStudio = RunService:IsStudio()

function HazardDebugVisualizer.attach(
	socket: Instance,
	hazardType: string,
	hazardInstance: any?,
	targetFolder: Instance?
)
	if not isStudio then return end
	if not socket:IsA("BasePart") then return end

	-- Check if debug is disabled via Workspace attribute
	if Workspace:GetAttribute("HazardDebugGui") == false then return end

	-- Remove any existing billboard on this socket
	if activeBillboards[socket] then
		activeBillboards[socket]:Destroy()
		activeBillboards[socket] = nil
	end

	-- Compact pill badge
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HazardDebugGui"
	billboard.Adornee = socket
	billboard.Size = UDim2.new(0, 130, 0, 22)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120 -- Only visible when within close/medium range
	billboard.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Name = "Container"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0) -- Fully rounded pill shape
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.3
	stroke.Color = hazardInstance and Color3.fromRGB(0, 230, 118) or Color3.fromRGB(240, 140, 40)
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 10
	label.TextScaled = false
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center

	-- Format single-line concise text: e.g. "🟢 RP | 1.5 rad/s" or "🔴 GiantGear"
	local shortName = hazardType
	if hazardType == "RotatingPlatform" then
		shortName = "RP"
	elseif hazardType == "RotatingArms" then
		shortName = "RotatingArms"
	elseif hazardType == "VerticalLift" then
		shortName = "Lift"
	elseif hazardType == "DisappearingTiles" or hazardType == "DisappearingTile" then
		shortName = "Tiles"
	end

	if hazardInstance then
		local telemetry = ""
		if typeof(hazardInstance.speed) == "number" then
			telemetry = string.format(" %.1f rad/s", hazardInstance.speed)
		end
		label.Text = string.format("🟢 %s%s", shortName, telemetry)
		label.TextColor3 = Color3.fromRGB(200, 255, 220)
	else
		label.Text = string.format("🔴 %s", shortName)
		label.TextColor3 = Color3.fromRGB(255, 180, 180)
	end

	label.Parent = frame
	billboard.Parent = socket
	activeBillboards[socket] = billboard
end

function HazardDebugVisualizer.detach(socket: Instance)
	if activeBillboards[socket] then
		activeBillboards[socket]:Destroy()
		activeBillboards[socket] = nil
	end
end

return HazardDebugVisualizer
