-- Client Settings Controller
-- Manages Settings UI visibility with TopbarPlus and binds volume sliders to settings changes
-- Place in: src/client/Controllers/SettingsController.client.luau -> StarterPlayer.StarterPlayerScripts.Client.Controllers.SettingsController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIFolder = SharedFolder:WaitForChild("UI")
local Slider = require(UIFolder:WaitForChild("Slider"))
local Icon = require(SharedFolder:WaitForChild("TopbarPlus"):WaitForChild("Icon"))
local OpenFrame = require(UIFolder:WaitForChild("OpenFrame"))
local ButtonFunctionality = require(UIFolder:WaitForChild("ButtonFunctionality"))

-- Create the TopbarPlus icon for Settings immediately
local settingsIcon = Icon.new()
	:setName("SettingsButton")
	:setImage("rbxassetid://18209577633")
	:setCaption("Settings")

-- Self-contained helper to find or construct the SettingsFrame UI autonomously
local function getOrCreateSettingsFrame()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local tabs = playerGui:FindFirstChild("Tabs")
	if not tabs then
		tabs = Instance.new("ScreenGui")
		tabs.Name = "Tabs"
		tabs.DisplayOrder = 10
		tabs.ResetOnSpawn = false
		tabs.IgnoreGuiInset = true
		tabs.Parent = playerGui
	end

	local settingsFrame = tabs:FindFirstChild("SettingsFrame")
	if settingsFrame then
		return settingsFrame
	end

	-- Create self-contained SettingsFrame
	settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	settingsFrame.Size = UDim2.new(0, 480, 0, 180)
	settingsFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	settingsFrame.BackgroundTransparency = 0.15
	settingsFrame.Visible = false
	settingsFrame.Parent = tabs

	local settingsCorner = Instance.new("UICorner")
	settingsCorner.CornerRadius = UDim.new(0, 16)
	settingsCorner.Parent = settingsFrame

	local settingsStroke = Instance.new("UIStroke")
	settingsStroke.Color = Color3.fromRGB(255, 215, 0)
	settingsStroke.Thickness = 2
	settingsStroke.Parent = settingsFrame

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Position = UDim2.new(0, 20, 0, 15)
	header.Size = UDim2.new(1, -40, 0, 40)
	header.BackgroundTransparency = 1
	header.Parent = settingsFrame

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Name = "Title"
	headerTitle.Size = UDim2.new(0, 200, 1, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "SETTINGS ⚙️"
	headerTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	headerTitle.TextSize = 22
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	-- Music Setting Row
	local musicSetting = Instance.new("Frame")
	musicSetting.Name = "MusicSetting"
	musicSetting.Position = UDim2.new(0, 20, 0, 75)
	musicSetting.Size = UDim2.new(1, -40, 0, 65)
	musicSetting.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
	musicSetting.BackgroundTransparency = 0.3
	musicSetting.Parent = settingsFrame

	local msCorner = Instance.new("UICorner")
	msCorner.CornerRadius = UDim.new(0, 12)
	msCorner.Parent = musicSetting

	local musicLabel = Instance.new("TextLabel")
	musicLabel.Name = "Label"
	musicLabel.Position = UDim2.new(0, 15, 0, 0)
	musicLabel.Size = UDim2.new(0, 130, 1, 0)
	musicLabel.BackgroundTransparency = 1
	musicLabel.Text = "MUSIC VOLUME"
	musicLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	musicLabel.TextSize = 13
	musicLabel.Font = Enum.Font.GothamBold
	musicLabel.TextXAlignment = Enum.TextXAlignment.Left
	musicLabel.Parent = musicSetting

	local musicSlider = Instance.new("Frame")
	musicSlider.Name = "MusicSlider"
	musicSlider.Position = UDim2.new(0, 170, 0, 95)
	musicSlider.Size = UDim2.new(1, -210, 0, 24)
	musicSlider.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
	musicSlider.Parent = settingsFrame

	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(0, 12)
	sliderCorner.Parent = musicSlider

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0.5, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
	fill.Parent = musicSlider

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 12)
	fillCorner.Parent = fill

	local knob = Instance.new("TextButton")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0.5, 0, 0.5, 0)
	knob.Size = UDim2.new(0, 28, 0, 28)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.Text = ""
	knob.Parent = musicSlider

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	return settingsFrame
end

local settingsFrame = getOrCreateSettingsFrame()
local header = settingsFrame:WaitForChild("Header")
local closeButton = header:WaitForChild("Close")
local musicSlider = settingsFrame:WaitForChild("MusicSlider")
local knob = musicSlider:WaitForChild("Knob")

-- Client-side BindableEvent for immediate volume sync with MusicController
local volumeEvent = ReplicatedStorage:FindFirstChild("MusicVolumeChanged")
if not volumeEvent then
	volumeEvent = Instance.new("BindableEvent")
	volumeEvent.Name = "MusicVolumeChanged"
	volumeEvent.Parent = ReplicatedStorage
end

-- Server-side RemoteEvent for persistent volume setting
local updateVolumeSettingRemote = ReplicatedStorage:FindFirstChild("UpdateVolumeSetting")
if not updateVolumeSettingRemote then
	updateVolumeSettingRemote = Instance.new("RemoteEvent")
	updateVolumeSettingRemote.Name = "UpdateVolumeSetting"
	updateVolumeSettingRemote.Parent = ReplicatedStorage
end

local otherData = LocalPlayer:WaitForChild("OtherData", 10)
local savedVolume = 0.3
if otherData then
	local savedVolumeVal = otherData:WaitForChild("MusicVolume", 5)
	if savedVolumeVal then
		savedVolume = savedVolumeVal.Value
	end
end

-- Flag to prevent recursion loop during toggles
local isToggling = false

-- Synchronize topbar icon state with frame visibility
settingsIcon.selected:Connect(function()
	if isToggling then return end
	isToggling = true
	if not settingsFrame.Visible then
		OpenFrame.ToggleFrame("SettingsFrame")
	end
	isToggling = false
end)

settingsIcon.deselected:Connect(function()
	if isToggling then return end
	isToggling = true
	if settingsFrame.Visible then
		OpenFrame.ToggleFrame("SettingsFrame")
	end
	isToggling = false
end)

-- Deselect topbar icon if frame becomes invisible via Close button or other menus
settingsFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if not settingsFrame.Visible then
		if settingsIcon.isSelected then
			isToggling = true
			settingsIcon:deselect()
			isToggling = false
		end
	end
end)

-- Setup Close Button with standard click feedback
local closeButtonScale = closeButton:FindFirstChildOfClass("UIScale")
ButtonFunctionality.SetupButton(closeButton, closeButtonScale, {
	playHoverSound = true,
	playClickSound = true,
	onClickCallback = function()
		OpenFrame.ToggleFrame("SettingsFrame")
	end
})

-- Initialize the volume slider with 10% (0.1) step snapping
local sliderInstance = Slider.new(musicSlider, knob, function(value)
	volumeEvent:Fire(value)
	updateVolumeSettingRemote:FireServer(value)
end, 0.1)

sliderInstance:SetValue(savedVolume)
