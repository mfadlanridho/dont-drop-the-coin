--!nonstrict
--[[
    NotificationService.luau
    Central UI Notification Service for banner announcements and toast messages.
    Location: src/shared/UI/NotificationService.luau (Syncs to ReplicatedStorage.Shared.UI.NotificationService)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local NotificationService = {}

local activeBannerThread: thread? = nil
local activeBannerFrame: Frame? = nil

local function playSound(soundName: string)
	pcall(function()
		local sounds = ReplicatedStorage:FindFirstChild("Sounds")
		local guiSounds = sounds and sounds:FindFirstChild("GuisSounds")
		local sound = guiSounds and (guiSounds:FindFirstChild(soundName) or guiSounds:FindFirstChild("UI_Close") or guiSounds:FindFirstChild("Close_UI") or guiSounds:FindFirstChild("Open_UI"))
		if sound then
			local clone = sound:Clone()
			clone.Parent = SoundService
			clone:Play()
			clone.Ended:Connect(function()
				clone:Destroy()
			end)
		end
	end)
end

local function getNotificationScreenGui(): ScreenGui?
	local player = Players.LocalPlayer
	if not player then return nil end
	local playerGui = player:WaitForChild("PlayerGui", 10) :: PlayerGui?
	if not playerGui then return nil end

	local gui = playerGui:FindFirstChild("NotificationServiceGui") :: ScreenGui?
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "NotificationServiceGui"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 100
		gui.Parent = playerGui
	end
	return gui
end

export type BannerConfig = {
	Title: string?,
	Description: string?,
	Duration: number?,
	Color: Color3?,
	SoundName: string?,
}

local function buildFallbackBannerTemplate(): Frame
	local frame = Instance.new("Frame")
	frame.Name = "BannerTemplate"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0.1, 0)
	frame.Size = UDim2.new(0.4, 0, 0.12, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2.5
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0.12, 0)
	title.Size = UDim2.new(0.9, 0, 0.35, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "ANNOUNCEMENT"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextScaled = true
	title.Parent = frame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1.5
	titleStroke.Parent = title

	local desc = Instance.new("TextLabel")
	desc.Name = "Description"
	desc.AnchorPoint = Vector2.new(0.5, 0)
	desc.Position = UDim2.new(0.5, 0, 0.52, 0)
	desc.Size = UDim2.new(0.9, 0, 0.38, 0)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.GothamMedium
	desc.Text = ""
	desc.TextColor3 = Color3.fromRGB(240, 240, 240)
	desc.TextScaled = true
	desc.Parent = frame

	return frame
end

local function getBannerTemplate(): Frame?
	local player = Players.LocalPlayer
	if not player then return buildFallbackBannerTemplate() end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return buildFallbackBannerTemplate() end

	local notifGui = playerGui:FindFirstChild("NotificationGui") or playerGui:FindFirstChild("NotificationServiceGui")
	if notifGui then
		local template = notifGui:FindFirstChild("BannerTemplate")
		if template and template:IsA("Frame") then
			return template
		end
	end

	-- Search in ReplicatedStorage
	local replicatedUI = ReplicatedStorage:FindFirstChild("UI") or ReplicatedStorage:FindFirstChild("Assets") or ReplicatedStorage:FindFirstChild("Shared")
	if replicatedUI then
		local template = replicatedUI:FindFirstChild("BannerTemplate", true)
		if template and template:IsA("Frame") then
			return template
		end
	end

	return buildFallbackBannerTemplate()
end

function NotificationService.showBanner(config: BannerConfig)
	config = config or {}
	local titleText = config.Title or "ANNOUNCEMENT"
	local descText = config.Description or ""
	local displayDuration = config.Duration or 5
	local accentColor = config.Color or Color3.fromRGB(255, 215, 0)

	local screenGui = getNotificationScreenGui()
	if not screenGui then return end

	-- Clean up currently active banner
	if activeBannerFrame and activeBannerFrame.Parent then
		activeBannerFrame:Destroy()
		activeBannerFrame = nil
	end

	local template = getBannerTemplate()
	if not template then
		warn("[NotificationService] BannerTemplate not available!")
		return
	end

	-- Clone template
	local banner = template:Clone()
	banner.Name = "ActiveAnnouncementBanner"
	banner.Visible = true
	banner.Parent = screenGui

	-- Update Title text & color (preserving UIStroke title outline)
	local titleLabel = banner:FindFirstChild("Title", true)
	if titleLabel and titleLabel:IsA("TextLabel") then
		titleLabel.Text = titleText
		if config.Color then
			titleLabel.TextColor3 = accentColor
		end
	end

	-- Update Description text
	local descLabel = banner:FindFirstChild("Description", true)
	if descLabel and descLabel:IsA("TextLabel") then
		descLabel.Text = descText
	end

	-- Update outer frame UIStroke border color
	local stroke = banner:FindFirstChildOfClass("UIStroke")
	if stroke and config.Color then
		stroke.Color = accentColor
	end

	-- Ensure UIScale exists for animation
	local scale = banner:FindFirstChildWhichIsA("UIScale", true)
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = banner
	end
	scale.Scale = 0

	activeBannerFrame = banner

	-- Play sound
	playSound(config.SoundName or "Open_UI")

	-- Entrance Animation
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	-- Schedule Exit Animation
	if activeBannerThread then
		task.cancel(activeBannerThread)
	end

	activeBannerThread = task.spawn(function()
		task.wait(displayDuration)
		if banner and banner.Parent then
			playSound("UI_Close")
			local exitTween = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Scale = 0,
			})
			exitTween:Play()
			exitTween.Completed:Wait()
			if banner and banner.Parent then
				banner:Destroy()
			end
			if activeBannerFrame == banner then
				activeBannerFrame = nil
			end
		end
	end)
end

function NotificationService.showToast(message: string, messageType: string?, duration: number?)
	duration = duration or 2.5
	local player = Players.LocalPlayer
	if not player then return end
	local playerGui = player:FindFirstChild("PlayerGui")
	local tabs = playerGui and playerGui:FindFirstChild("Tabs")
	local notify = tabs and tabs:FindFirstChild("Notify")

	if notify and notify:IsA("TextLabel") then
		notify.Text = message
		notify.Visible = true
		task.delay(duration, function()
			if notify.Text == message then
				notify.Visible = false
			end
		end)
	else
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = messageType or "Notice",
				Text = message,
				Duration = duration,
			})
		end)
	end
end

return NotificationService
