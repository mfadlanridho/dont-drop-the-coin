-- Reusable Slider Module for Roblox Client UI
-- Handles dragging a knob along a slider track and returning a percentage value (0.0 - 1.0)
-- Place in: src/shared/UI/Slider.luau -> ReplicatedStorage.Shared.UI.Slider

local UserInputService = game:GetService("UserInputService")

local Slider = {}
Slider.__index = Slider

local function snapValue(val: number, step: number?): number
	val = math.clamp(val, 0, 1)
	if step and step > 0 then
		val = math.round(val / step) * step
		val = math.round(val * 100000) / 100000 -- resolve floating point precision inaccuracies
	end
	return math.clamp(val, 0, 1)
end

function Slider.new(sliderFrame: Frame, knob: GuiButton, callback: (value: number) -> (), step: number?)
	local self = setmetatable({}, Slider)

	self.SliderFrame = sliderFrame
	self.Knob = knob
	self.Callback = callback
	self.Step = step
	self.CurrentValue = nil
	self.IsDragging = false
	self.ActiveInput = nil

	-- Set anchor point of knob to center and enable input processing
	self.Knob.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Knob.Active = true
	self.SliderFrame.Active = true

	-- Auto-create Fill progress bar if missing in target slider frame
	local fill = self.SliderFrame:FindFirstChild("Fill")
	if not fill then
		fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		fill.Parent = self.SliderFrame

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = fill
	end

	-- Handle slider input start (mouse down / touch start on knob)
	self.Knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.IsDragging = true
			self.ActiveInput = input
			self:Update(input.Position)
		end
	end)

	-- Listen globally to input changes (dragging) and ends (releasing)
	UserInputService.InputChanged:Connect(function(input)
		if self.IsDragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement or (input.UserInputType == Enum.UserInputType.Touch and input == self.ActiveInput) then
				self:Update(input.Position)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if self.IsDragging then
			if input.UserInputType == Enum.UserInputType.MouseButton1 or (input.UserInputType == Enum.UserInputType.Touch and input == self.ActiveInput) then
				self.IsDragging = false
				self.ActiveInput = nil
			end
		end
	end)

	-- Handle clicking directly on the slider track to jump to that value
	self.SliderFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.IsDragging = true
			self.ActiveInput = input
			self:Update(input.Position)
		end
	end)

	return self
end

function Slider:Update(inputPosition: Vector3)
	local framePos = self.SliderFrame.AbsolutePosition
	local frameSize = self.SliderFrame.AbsoluteSize

	if frameSize.X <= 0 then
		return
	end

	-- Calculate percentage based on mouse position along the slider track
	local relativeX = inputPosition.X - framePos.X
	local rawPercentage = relativeX / frameSize.X
	local percentage = snapValue(rawPercentage, self.Step)

	if self.CurrentValue == percentage then
		return
	end
	self.CurrentValue = percentage

	-- Update the knob UI position
	self.Knob.Position = UDim2.new(percentage, 0, 0.5, 0)

	-- Update the fill progress bar if one exists inside the slider track
	local fill = self.SliderFrame:FindFirstChild("Fill")
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.new(percentage, 0, 1, 0)
	end

	-- Trigger callback
	self.Callback(percentage)
end

function Slider:SetValue(percentage: number)
	percentage = snapValue(percentage, self.Step)
	self.CurrentValue = percentage

	-- Update the knob UI position
	self.Knob.Position = UDim2.new(percentage, 0, 0.5, 0)

	-- Update the fill progress bar if one exists inside the slider track
	local fill = self.SliderFrame:FindFirstChild("Fill")
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.new(percentage, 0, 1, 0)
	end

	-- Trigger callback
	self.Callback(percentage)
end

return Slider
