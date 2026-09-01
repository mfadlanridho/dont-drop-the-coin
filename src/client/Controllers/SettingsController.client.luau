-- Client Settings Controller
-- Manages Settings UI visibility and binds volume sliders to settings changes.
-- Supports both static Studio UI and autonomous fallback creation.
-- Location: src/client/Controllers/SettingsController.client.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIFolder = SharedFolder:WaitForChild("UI")
local Slider = require(UIFolder:WaitForChild("Slider"))
local OpenFrame = require(UIFolder:WaitForChild("OpenFrame"))
local ButtonFunctionality = require(UIFolder:WaitForChild("ButtonFunctionality"))

-- Helper to find or autonomously construct SettingsFrame
local function getOrCreateSettingsFrame(): Frame
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local tabs = playerGui:WaitForChild("Tabs", 10) :: ScreenGui?
	if not tabs then
		tabs = playerGui:FindFirstChild("Tabs") :: ScreenGui?
	end
	assert(tabs, "PlayerGui.Tabs ScreenGui not found!")

	local settingsFrame = tabs:FindFirstChild("Settings") or tabs:FindFirstChild("SettingsFrame") :: Frame?
	if settingsFrame then
		return settingsFrame
	end

	-- Create self-contained premium SettingsFrame fallback
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

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Position = UDim2.new(0, 20, 0, 15)
	titleLabel.Size = UDim2.new(1, -70, 0, 30)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "SETTINGS"
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.TextSize = 22
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = settingsFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -15, 0, 15)
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = settingsFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	local closeScale = Instance.new("UIScale")
	closeScale.Parent = closeBtn

	local volumeContainer = Instance.new("Frame")
	volumeContainer.Name = "VolumeContainer"
	volumeContainer.Position = UDim2.new(0, 20, 0, 70)
	volumeContainer.Size = UDim2.new(1, -40, 0, 80)
	volumeContainer.BackgroundTransparency = 1
	volumeContainer.Parent = settingsFrame

	local volLabel = Instance.new("TextLabel")
	volLabel.Name = "VolumeLabel"
	volLabel.Position = UDim2.new(0, 0, 0, 0)
	volLabel.Size = UDim2.new(1, 0, 0, 25)
	volLabel.BackgroundTransparency = 1
	volLabel.Text = "MUSIC VOLUME"
	volLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	volLabel.TextSize = 16
	volLabel.Font = Enum.Font.GothamMedium
	volLabel.TextXAlignment = Enum.TextXAlignment.Left
	volLabel.Parent = volumeContainer

	local trackFrame = Instance.new("Frame")
	trackFrame.Name = "MusicVolumeSlider"
	trackFrame.Position = UDim2.new(0, 0, 0, 35)
	trackFrame.Size = UDim2.new(1, 0, 0, 16)
	trackFrame.BackgroundColor3 = Color3.fromRGB(40, 48, 68)
	trackFrame.Parent = volumeContainer

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 8)
	trackCorner.Parent = trackFrame

	local knobFrame = Instance.new("Frame")
	knobFrame.Name = "Knob"
	knobFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	knobFrame.Position = UDim2.new(0.3, 0, 0.5, 0)
	knobFrame.Size = UDim2.new(0, 28, 0, 28)
	knobFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	knobFrame.Parent = trackFrame

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knobFrame

	return settingsFrame
end

local settingsFrame = getOrCreateSettingsFrame()
local volumeContainer = settingsFrame:WaitForChild("VolumeContainer")
local musicSlider = volumeContainer:WaitForChild("MusicVolumeSlider") :: Frame
local knob = musicSlider:WaitForChild("Knob") :: Frame
local closeButton = settingsFrame:WaitForChild("CloseButton") :: TextButton

-- ReplicatedStorage BindableEvent for music volume updates
local volumeEvent = ReplicatedStorage:FindFirstChild("MusicVolumeChanged") :: BindableEvent?
if not volumeEvent then
	volumeEvent = Instance.new("BindableEvent")
	volumeEvent.Name = "MusicVolumeChanged"
	volumeEvent.Parent = ReplicatedStorage
end

-- RemoteEvent to persist settings to server ProfileStore
local remotesFolder = SharedFolder:WaitForChild("Remotes")
local Remotes = require(remotesFolder :: ModuleScript)
local updateVolumeSettingRemote = pcall(function() return Remotes.Get("UpdateMusicVolume") end) and Remotes.Get("UpdateMusicVolume") or nil

-- Fetch saved volume from player leaderstats / data folder if available
local otherData = LocalPlayer:WaitForChild("OtherData", 10)
local savedVolume = 0.3
if otherData then
	local savedVolumeVal = otherData:WaitForChild("MusicVolume", 5)
	if savedVolumeVal then
		savedVolume = savedVolumeVal.Value
	end
end

-- Setup Close Button with standard click feedback
local closeButtonScale = closeButton:FindFirstChildOfClass("UIScale")
ButtonFunctionality.SetupButton(closeButton, closeButtonScale, {
	playHoverSound = true,
	playClickSound = true,
	onClickCallback = function()
		OpenFrame.ToggleFrame(settingsFrame.Name)
	end,
})

-- Initialize the volume slider with 10% (0.1) step snapping
local sliderInstance = Slider.new(musicSlider, knob, function(value)
	volumeEvent:Fire(value)
	if updateVolumeSettingRemote then
		updateVolumeSettingRemote:FireServer(value)
	end
end, 0.1)

sliderInstance:SetValue(savedVolume)
