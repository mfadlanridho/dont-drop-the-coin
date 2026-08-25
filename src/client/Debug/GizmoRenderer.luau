local Workspace = game:GetService("Workspace")

local GizmoRenderer = {}
GizmoRenderer.__index = GizmoRenderer

local DEFAULT_LINE_THICKNESS = 0.2
local DEFAULT_LINE_TRANSPARENCY = 0.1
local DEFAULT_MARKER_SIZE = 0.45
local DEFAULT_MARKER_TRANSPARENCY = 0.05
local DEFAULT_WIRE_SPHERE_TRANSPARENCY = 0.75
local DEFAULT_LABEL_TEXT_SIZE = 14
local DEFAULT_LABEL_STUDS_OFFSET = Vector3.new(0, 1.2, 0)

function GizmoRenderer.new(folderName: string, config: { [string]: any }?)
	local folder = Workspace:FindFirstChild(folderName)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = Workspace
	end

	return setmetatable({
		folder = folder,
		lineThickness = if config ~= nil and config.lineThickness ~= nil then config.lineThickness else DEFAULT_LINE_THICKNESS,
		lineTransparency = if config ~= nil and config.lineTransparency ~= nil then config.lineTransparency else DEFAULT_LINE_TRANSPARENCY,
		markerSize = if config ~= nil and config.markerSize ~= nil then config.markerSize else DEFAULT_MARKER_SIZE,
		markerTransparency = if config ~= nil and config.markerTransparency ~= nil then config.markerTransparency else DEFAULT_MARKER_TRANSPARENCY,
		wireSphereTransparency = if config ~= nil and config.wireSphereTransparency ~= nil then config.wireSphereTransparency else DEFAULT_WIRE_SPHERE_TRANSPARENCY,
		labelTextSize = if config ~= nil and config.labelTextSize ~= nil then config.labelTextSize else DEFAULT_LABEL_TEXT_SIZE,
		labelStudsOffset = if config ~= nil and config.labelStudsOffset ~= nil then config.labelStudsOffset else DEFAULT_LABEL_STUDS_OFFSET,
	}, GizmoRenderer)
end

function GizmoRenderer:getLine(name: string, color: Color3): BasePart
	local line = self.folder:FindFirstChild(name)
	if line == nil then
		line = Instance.new("Part")
		line.Name = name
		line.Anchored = true
		line.CanCollide = false
		line.CanTouch = false
		line.CanQuery = false
		line.Material = Enum.Material.Neon
		line.Color = color
		line.Transparency = self.lineTransparency
		line.Size = Vector3.new(self.lineThickness, self.lineThickness, 0.05)
		line.Parent = self.folder
	end

	return line :: BasePart
end

function GizmoRenderer:getMarker(name: string, color: Color3): BasePart
	local marker = self.folder:FindFirstChild(name)
	if marker == nil then
		marker = Instance.new("Part")
		marker.Name = name
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanTouch = false
		marker.CanQuery = false
		marker.Shape = Enum.PartType.Ball
		marker.Material = Enum.Material.Neon
		marker.Color = color
		marker.Transparency = self.markerTransparency
		marker.Size = Vector3.one * self.markerSize
		marker.Parent = self.folder
	end

	return marker :: BasePart
end

function GizmoRenderer:getWireSphere(name: string, color: Color3, radius: number?): SphereHandleAdornment
	local sphere = self.folder:FindFirstChild(name)
	if sphere ~= nil and not sphere:IsA("SphereHandleAdornment") then
		sphere:Destroy()
		sphere = nil
	end

	if sphere == nil then
		sphere = Instance.new("SphereHandleAdornment")
		sphere.Name = name
		sphere.Adornee = Workspace.Terrain
		sphere.AlwaysOnTop = false
		sphere.Parent = self.folder
	end

	self:setWireSphere(sphere :: SphereHandleAdornment, Vector3.zero, radius or self.markerSize, color)

	return sphere :: SphereHandleAdornment
end

function GizmoRenderer:getPointLabel(name: string, text: string, color: Color3): BasePart
	local anchor = self.folder:FindFirstChild(name)
	if anchor ~= nil and not anchor:IsA("Part") then
		anchor:Destroy()
		anchor = nil
	end

	if anchor == nil then
		anchor = Instance.new("Part")
		anchor.Name = name
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanTouch = false
		anchor.CanQuery = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.05, 0.05, 0.05)
		anchor.Parent = self.folder
	end

	local billboard = anchor:FindFirstChild("Billboard")
	if billboard ~= nil and not billboard:IsA("BillboardGui") then
		billboard:Destroy()
		billboard = nil
	end

	if billboard == nil then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "Billboard"
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.Size = UDim2.fromOffset(140, 28)
		billboard.StudsOffsetWorldSpace = self.labelStudsOffset
		billboard.Parent = anchor

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Text"
		textLabel.BackgroundTransparency = 1
		textLabel.Size = UDim2.fromScale(1, 1)
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextScaled = false
		textLabel.TextSize = self.labelTextSize
		textLabel.TextStrokeTransparency = 0.35
		textLabel.Parent = billboard
	end

	self:setPointLabel(anchor :: BasePart, Vector3.zero, text, color)
	return anchor :: BasePart
end

function GizmoRenderer:setLine(line: BasePart, fromPosition: Vector3, toPosition: Vector3, color: Color3?)
	local delta = toPosition - fromPosition
	local length = delta.Magnitude

	if color ~= nil then
		line.Color = color
	end

	line.Transparency = self.lineTransparency

	if length <= 1e-4 then
		line.Size = Vector3.new(self.lineThickness, self.lineThickness, 0.05)
		line.CFrame = CFrame.new(fromPosition)
		return
	end

	local midpoint = fromPosition + (delta * 0.5)
	line.Size = Vector3.new(self.lineThickness, self.lineThickness, length)
	line.CFrame = CFrame.lookAt(midpoint, toPosition)
end

function GizmoRenderer:setMarker(marker: BasePart, position: Vector3, color: Color3?)
	if color ~= nil then
		marker.Color = color
	end

	marker.Transparency = self.markerTransparency
	marker.Size = Vector3.one * self.markerSize
	marker.CFrame = CFrame.new(position)
end

function GizmoRenderer:setWireSphere(sphere: SphereHandleAdornment, position: Vector3, radius: number?, color: Color3?)
	local sphereRadius = radius or self.markerSize
	sphere.CFrame = CFrame.new(position)
	sphere.Radius = sphereRadius
	sphere.Transparency = self.wireSphereTransparency

	if color ~= nil then
		sphere.Color3 = color
	end
end

function GizmoRenderer:setPointLabel(anchor: BasePart, position: Vector3, text: string, color: Color3?)
	anchor.CFrame = CFrame.new(position)
	anchor.Transparency = 1

	local billboard = anchor:FindFirstChild("Billboard")
	if billboard == nil or not billboard:IsA("BillboardGui") then
		return
	end

	billboard.Enabled = true
	local textLabel = billboard:FindFirstChild("Text")
	if textLabel == nil or not textLabel:IsA("TextLabel") then
		return
	end

	textLabel.Text = text
	if color ~= nil then
		textLabel.TextColor3 = color
	end
end

function GizmoRenderer:hideLine(line: BasePart)
	line.Transparency = 1
	line.Size = Vector3.new(self.lineThickness, self.lineThickness, 0.05)
end

function GizmoRenderer:hideMarker(marker: BasePart)
	marker.Transparency = 1
	marker.Size = Vector3.one * self.markerSize
end

function GizmoRenderer:hideWireSphere(sphere: SphereHandleAdornment)
	sphere.Transparency = 1
end

function GizmoRenderer:hidePointLabel(anchor: BasePart)
	anchor.Transparency = 1
	local billboard = anchor:FindFirstChild("Billboard")
	if billboard ~= nil and billboard:IsA("BillboardGui") then
		billboard.Enabled = false
	end
end

function GizmoRenderer:hideAll()
	for _, instance in ipairs(self.folder:GetChildren()) do
		if instance:IsA("SphereHandleAdornment") then
			self:hideWireSphere(instance)
			continue
		end

		if not instance:IsA("BasePart") then
			continue
		end

		if instance:FindFirstChild("Billboard") ~= nil then
			self:hidePointLabel(instance)
			continue
		end

		if instance.Shape == Enum.PartType.Ball then
			self:hideMarker(instance)
		else
			self:hideLine(instance)
		end
	end
end

return GizmoRenderer
