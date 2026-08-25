local DebugGuiView = {}
DebugGuiView.__index = DebugGuiView

local GUI_NAME = "DeveloperDebugGui"
local ROOT_SIZE = UDim2.fromOffset(420, 340)
local ROOT_POSITION = UDim2.fromOffset(16, 16)
local PANEL_BACKGROUND = Color3.fromRGB(13, 17, 23)
local PANEL_BORDER = Color3.fromRGB(62, 72, 92)
local PANEL_SURFACE = Color3.fromRGB(20, 26, 36)
local PANEL_SURFACE_ALT = Color3.fromRGB(28, 35, 48)
local PANEL_TEXT = Color3.fromRGB(238, 242, 248)
local PANEL_TEXT_MUTED = Color3.fromRGB(149, 161, 184)
local PANEL_ACCENT = Color3.fromRGB(76, 163, 255)

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function clearChildren(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("UIListLayout") or child:IsA("UIPadding") then
			continue
		end

		child:Destroy()
	end
end

function DebugGuiView.new(playerGui)
	local self = setmetatable({}, DebugGuiView)

	local existingGui = playerGui:FindFirstChild(GUI_NAME)
	if existingGui ~= nil then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = GUI_NAME
	screenGui.DisplayOrder = 200
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local rootFrame = Instance.new("Frame")
	rootFrame.Name = "Root"
	rootFrame.BackgroundColor3 = PANEL_BACKGROUND
	rootFrame.Position = ROOT_POSITION
	rootFrame.Size = ROOT_SIZE
	rootFrame.Parent = screenGui
	createCorner(rootFrame, 16)
	createStroke(rootFrame, PANEL_BORDER, 0.15)

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundTransparency = 1
	titleBar.Position = UDim2.fromOffset(14, 12)
	titleBar.Size = UDim2.new(1, -28, 0, 48)
	titleBar.Parent = rootFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(0.6, 0, 0, 24)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "Developer Debug"
	titleLabel.TextColor3 = PANEL_TEXT
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Position = UDim2.fromOffset(0, 24)
	subtitleLabel.Size = UDim2.new(0.7, 0, 0, 20)
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.Text = "Studio-only debug panel"
	subtitleLabel.TextColor3 = PANEL_TEXT_MUTED
	subtitleLabel.TextSize = 13
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.Parent = titleBar

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(1, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Position = UDim2.new(1, 0, 0, 0)
	hintLabel.Size = UDim2.new(0.35, 0, 0, 20)
	hintLabel.Font = Enum.Font.GothamMedium
	hintLabel.Text = "P to toggle"
	hintLabel.TextColor3 = PANEL_TEXT_MUTED
	hintLabel.TextSize = 13
	hintLabel.TextXAlignment = Enum.TextXAlignment.Right
	hintLabel.Parent = titleBar

	local tabBar = Instance.new("ScrollingFrame")
	tabBar.Name = "Tabs"
	tabBar.Active = true
	tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabBar.ScrollingDirection = Enum.ScrollingDirection.X
	tabBar.BackgroundTransparency = 1
	tabBar.BorderSizePixel = 0
	tabBar.CanvasSize = UDim2.new()
	tabBar.Position = UDim2.fromOffset(14, 68)
	tabBar.ScrollBarImageColor3 = PANEL_ACCENT
	tabBar.ScrollBarThickness = 4
	tabBar.Size = UDim2.new(1, -28, 0, 34)
	tabBar.Parent = rootFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabBar

	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingRight = UDim.new(0, 4)
	tabPadding.Parent = tabBar

	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "Content"
	contentFrame.Active = true
	contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	contentFrame.BackgroundColor3 = PANEL_SURFACE
	contentFrame.BorderSizePixel = 0
	contentFrame.CanvasSize = UDim2.new()
	contentFrame.Position = UDim2.fromOffset(14, 112)
	contentFrame.ScrollBarImageColor3 = PANEL_ACCENT
	contentFrame.ScrollBarThickness = 6
	contentFrame.Size = UDim2.new(1, -28, 1, -126)
	contentFrame.Parent = rootFrame
	createCorner(contentFrame, 14)
	createStroke(contentFrame, PANEL_BORDER, 0.45)

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingBottom = UDim.new(0, 12)
	contentPadding.PaddingLeft = UDim.new(0, 12)
	contentPadding.PaddingRight = UDim.new(0, 12)
	contentPadding.PaddingTop = UDim.new(0, 12)
	contentPadding.Parent = contentFrame

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = contentFrame

	screenGui.Parent = playerGui

	self.screenGui = screenGui
	self.rootFrame = rootFrame
	self.titleLabel = titleLabel
	self.subtitleLabel = subtitleLabel
	self.hintLabel = hintLabel
	self.tabBar = tabBar
	self.contentFrame = contentFrame
	self.onPanelSelected = nil

	return self
end

function DebugGuiView:setPanelSelectedCallback(callback)
	self.onPanelSelected = callback
end

function DebugGuiView:render(state)
	self.rootFrame.Visible = state.visible
	if not state.visible then
		return
	end

	self.titleLabel.Text = state.title
	self.subtitleLabel.Text = state.subtitle
	self.hintLabel.Text = state.hintText

	-- Tab bar reconciliation
	local existingTabs: { [string]: TextButton } = {}
	for _, child in ipairs(self.tabBar:GetChildren()) do
		if child:IsA("TextButton") then
			existingTabs[child.Name] = child
		end
	end

	for index, panel in ipairs(state.panels) do
		local button = existingTabs[panel.key]
		if button ~= nil then
			button.BackgroundColor3 = if panel.selected then PANEL_ACCENT else PANEL_SURFACE_ALT
			button.TextColor3 = if panel.selected then PANEL_BACKGROUND else PANEL_TEXT
			button.LayoutOrder = index
			existingTabs[panel.key] = nil
		else
			button = Instance.new("TextButton")
			button.Name = panel.key
			button.AutoButtonColor = false
			button.BackgroundColor3 = if panel.selected then PANEL_ACCENT else PANEL_SURFACE_ALT
			button.LayoutOrder = index
			button.Size = UDim2.fromOffset(math.max(84, (#panel.displayName * 8) + 22), 28)
			button.Font = Enum.Font.GothamMedium
			button.Text = panel.displayName
			button.TextColor3 = if panel.selected then PANEL_BACKGROUND else PANEL_TEXT
			button.TextSize = 13
			button.Parent = self.tabBar
			createCorner(button, 10)

			button.Activated:Connect(function()
				if self.onPanelSelected ~= nil then
					self.onPanelSelected(panel.key)
				end
			end)
		end
	end

	for _, stale in pairs(existingTabs) do
		stale:Destroy()
	end

	-- Content area reconciliation
	local existingContent: { [string]: Instance } = {}
	for _, child in ipairs(self.contentFrame:GetChildren()) do
		if not (child:IsA("UIListLayout") or child:IsA("UIPadding")) then
			existingContent[child.Name] = child
		end
	end

	if state.placeholderText ~= nil then
		local ph = existingContent["Placeholder"]
		if ph ~= nil and ph:IsA("TextLabel") then
			ph.Text = state.placeholderText
			existingContent["Placeholder"] = nil
		else
			local placeholderLabel = Instance.new("TextLabel")
			placeholderLabel.Name = "Placeholder"
			placeholderLabel.BackgroundTransparency = 1
			placeholderLabel.Size = UDim2.new(1, 0, 0, 40)
			placeholderLabel.Font = Enum.Font.Gotham
			placeholderLabel.Text = state.placeholderText
			placeholderLabel.TextColor3 = PANEL_TEXT_MUTED
			placeholderLabel.TextSize = 14
			placeholderLabel.TextWrapped = true
			placeholderLabel.TextXAlignment = Enum.TextXAlignment.Left
			placeholderLabel.TextYAlignment = Enum.TextYAlignment.Top
			placeholderLabel.Parent = self.contentFrame
		end
		for key, stale in pairs(existingContent) do
			if key ~= "Placeholder" then
				stale:Destroy()
			end
		end
		return
	end

	for index, row in ipairs(state.rows) do
		local existing = existingContent[row.key]

		if row.rowType == "toggle" then
			local container = if existing ~= nil and existing:IsA("Frame") then existing else nil

			if container ~= nil then
				container.LayoutOrder = index
				local label = container:FindFirstChildOfClass("TextLabel")
				if label then label.Text = row.displayName end
				local btn = container:FindFirstChildOfClass("TextButton")
				if btn then
					local isOn = row.value == true
					btn.BackgroundColor3 = if isOn then Color3.fromRGB(34, 197, 94) else Color3.fromRGB(100, 116, 139)
					btn.Text = if isOn then "ON" else "OFF"
				end
				existingContent[row.key] = nil
			else
				container = Instance.new("Frame")
				container.Name = row.key
				container.BackgroundColor3 = PANEL_SURFACE_ALT
				container.LayoutOrder = index
				container.Size = UDim2.new(1, 0, 0, 32)
				container.Parent = self.contentFrame
				createCorner(container, 8)

				local label = Instance.new("TextLabel")
				label.BackgroundTransparency = 1
				label.Position = UDim2.fromOffset(10, 0)
				label.Size = UDim2.new(1, -90, 1, 0)
				label.Font = Enum.Font.Code
				label.Text = row.displayName
				label.TextColor3 = PANEL_TEXT
				label.TextSize = 14
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = container

				local isOn = row.value == true
				local toggleBtn = Instance.new("TextButton")
				toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
				toggleBtn.AutoButtonColor = false
				toggleBtn.BackgroundColor3 = if isOn then Color3.fromRGB(34, 197, 94) else Color3.fromRGB(100, 116, 139)
				toggleBtn.Position = UDim2.new(1, -8, 0.5, 0)
				toggleBtn.Size = UDim2.fromOffset(70, 22)
				toggleBtn.Font = Enum.Font.GothamBold
				toggleBtn.Text = if isOn then "ON" else "OFF"
				toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				toggleBtn.TextSize = 12
				toggleBtn.Parent = container
				createCorner(toggleBtn, 6)

				if row.callback ~= nil then
					local capturedRow = row
					toggleBtn.Activated:Connect(function()
						capturedRow.callback(not capturedRow.value)
					end)
				end
			end
		elseif row.rowType == "input" then
			local container = if existing ~= nil and existing:IsA("Frame") then existing else nil

			if container ~= nil then
				container.LayoutOrder = index
				local label = container:FindFirstChildOfClass("TextLabel")
				if label then label.Text = row.displayName end
				local textBox = container:FindFirstChildOfClass("TextBox")
				if textBox then
					if not textBox:IsFocused() then
						textBox.Text = tostring(row.value)
					end
				end
				existingContent[row.key] = nil
			else
				container = Instance.new("Frame")
				container.Name = row.key
				container.BackgroundColor3 = PANEL_SURFACE_ALT
				container.LayoutOrder = index
				container.Size = UDim2.new(1, 0, 0, 32)
				container.Parent = self.contentFrame
				createCorner(container, 8)

				local label = Instance.new("TextLabel")
				label.BackgroundTransparency = 1
				label.Position = UDim2.fromOffset(10, 0)
				label.Size = UDim2.new(1, -110, 1, 0)
				label.Font = Enum.Font.Code
				label.Text = row.displayName
				label.TextColor3 = PANEL_TEXT
				label.TextSize = 14
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = container

				local textBox = Instance.new("TextBox")
				textBox.AnchorPoint = Vector2.new(1, 0.5)
				textBox.BackgroundColor3 = PANEL_SURFACE
				textBox.Position = UDim2.new(1, -8, 0.5, 0)
				textBox.Size = UDim2.fromOffset(90, 22)
				textBox.Font = Enum.Font.Code
				textBox.Text = tostring(row.value)
				textBox.PlaceholderText = "Value"
				textBox.TextColor3 = PANEL_TEXT
				textBox.PlaceholderColor3 = PANEL_TEXT_MUTED
				textBox.TextSize = 12
				textBox.ClearTextOnFocus = false
				textBox.Parent = container
				createCorner(textBox, 6)
				createStroke(textBox, PANEL_BORDER, 0.4)

				if row.callback ~= nil then
					local capturedRow = row
					textBox.FocusLost:Connect(function(enterPressed)
						if enterPressed then
							capturedRow.callback(textBox.Text)
						else
							textBox.Text = tostring(capturedRow.value)
						end
					end)
				end
			end
		elseif row.rowType == "button" then
			local container = if existing ~= nil and existing:IsA("Frame") then existing else nil

			if container ~= nil then
				container.LayoutOrder = index
				local label = container:FindFirstChildOfClass("TextLabel")
				if label then label.Text = row.displayName end
				local btn = container:FindFirstChildOfClass("TextButton")
				if btn then
					btn.Text = tostring(row.value or "RUN")
				end
				existingContent[row.key] = nil
			else
				container = Instance.new("Frame")
				container.Name = row.key
				container.BackgroundColor3 = PANEL_SURFACE_ALT
				container.LayoutOrder = index
				container.Size = UDim2.new(1, 0, 0, 32)
				container.Parent = self.contentFrame
				createCorner(container, 8)

				local label = Instance.new("TextLabel")
				label.BackgroundTransparency = 1
				label.Position = UDim2.fromOffset(10, 0)
				label.Size = UDim2.new(1, -90, 1, 0)
				label.Font = Enum.Font.Code
				label.Text = row.displayName
				label.TextColor3 = PANEL_TEXT
				label.TextSize = 14
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = container

				local actionBtn = Instance.new("TextButton")
				actionBtn.AnchorPoint = Vector2.new(1, 0.5)
				actionBtn.AutoButtonColor = true
				actionBtn.BackgroundColor3 = PANEL_ACCENT
				actionBtn.Position = UDim2.new(1, -8, 0.5, 0)
				actionBtn.Size = UDim2.fromOffset(70, 22)
				actionBtn.Font = Enum.Font.GothamBold
				actionBtn.Text = tostring(row.value or "RUN")
				actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				actionBtn.TextSize = 12
				actionBtn.Parent = container
				createCorner(actionBtn, 6)

				if row.callback ~= nil then
					local capturedRow = row
					actionBtn.Activated:Connect(function()
						capturedRow.callback()
					end)
				end
			end
		else
			local rowLabel = if existing ~= nil and existing:IsA("TextLabel") then existing else nil

			if rowLabel ~= nil then
				rowLabel.Text = string.format("%s: %s", row.displayName, row.value)
				rowLabel.LayoutOrder = index
				existingContent[row.key] = nil
			else
				rowLabel = Instance.new("TextLabel")
				rowLabel.Name = row.key
				rowLabel.BackgroundColor3 = PANEL_SURFACE_ALT
				rowLabel.LayoutOrder = index
				rowLabel.Size = UDim2.new(1, 0, 0, 28)
				rowLabel.Font = Enum.Font.Code
				rowLabel.Text = string.format("%s: %s", row.displayName, row.value)
				rowLabel.TextColor3 = PANEL_TEXT
				rowLabel.TextSize = 14
				rowLabel.TextTruncate = Enum.TextTruncate.AtEnd
				rowLabel.TextXAlignment = Enum.TextXAlignment.Left
				rowLabel.Parent = self.contentFrame
				createCorner(rowLabel, 8)

				local padding = Instance.new("UIPadding")
				padding.PaddingLeft = UDim.new(0, 10)
				padding.PaddingRight = UDim.new(0, 10)
				padding.Parent = rowLabel
			end
		end
	end

	for _, stale in pairs(existingContent) do
		stale:Destroy()
	end
end

function DebugGuiView:destroy()
	if self.screenGui ~= nil then
		self.screenGui:Destroy()
		self.screenGui = nil
	end
end

return DebugGuiView
