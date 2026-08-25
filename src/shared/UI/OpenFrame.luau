-- OpenFrame Module
-- Central UI state manager for modal tab frames, screen dimming, and HUD isolation
-- Place in: src/shared/UI/OpenFrame.luau -> ReplicatedStorage.Shared.UI.OpenFrame

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local OpenFrame = {}

local player = Players.LocalPlayer

local UIEffects = require(script.Parent:WaitForChild("UIEffects"))

-- Tween settings
local BLACK_FADE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BLACK_FADE_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local CASH_FRAME_NAME = "Cash"        -- ScreenGui child to NOT hide
local SKIP_TAB_NAME = nil             -- Tabs child to NEVER touch

-- =====================================================================
-- HELPER: FIND TABS FOLDER (Supports PlayerGui.Tabs or PlayerGui.Menus.Tabs)
-- =====================================================================
local function getTabsFolder()
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end

	local tabs = playerGui:FindFirstChild("Tabs")
	if not tabs then
		local menus = playerGui:FindFirstChild("Menus")
		if menus then
			tabs = menus:FindFirstChild("Tabs")
		end
	end
	if not tabs then
		tabs = playerGui:FindFirstChild("Tabs", true) -- Recursive fallback
	end
	return tabs
end

-- =====================================================================
-- SCREEN GUI VISIBILITY CONTROL
-- =====================================================================
local function setScreenGuiVisible(state)
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = playerGui:FindFirstChild("ScreenGui") or playerGui:FindFirstChild("Menus")
	if not screenGui then return end

	for _, obj in ipairs(screenGui:GetChildren()) do
		if obj:IsA("GuiObject") and obj.Name ~= CASH_FRAME_NAME and obj.Name ~= "Carrying" and obj.Name ~= "Toggles" then
			obj.Visible = state
		end
	end
end

-- =====================================================================
-- TAB INITIALIZATION & FORCE RESET UI
-- =====================================================================
local function initializeTabScales()
	local tabsFolder = getTabsFolder()
	if tabsFolder then
		for _, frame in ipairs(tabsFolder:GetChildren()) do
			if frame:IsA("GuiObject") and frame.Name ~= "Black" then
				UIEffects.ensureUIScale(frame)
			end
		end
	end
end

-- Capture initial Studio scales before any resets run
task.spawn(function()
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if playerGui then
		task.wait(0.5)
		initializeTabScales()
	end
end)

local function forceResetUI()
	UIEffects.cancelPendingCloses()
	
	local tabsFolder = getTabsFolder()
	if tabsFolder then
		for _, frame in ipairs(tabsFolder:GetChildren()) do
			if frame:IsA("GuiObject") then
				frame.Visible = false
				local s, targetScale = UIEffects.ensureUIScale(frame)
				if s then
					s.Scale = targetScale
				end
			end
		end
	end

	local blur = Lighting:FindFirstChild("Blur")
	if blur then
		blur.Enabled = false
	end

	setScreenGuiVisible(true)
end

-- =====================================================================
-- CHARACTER DEATH / RESPAWN CLEANUP
-- =====================================================================
local function hookCharacter(char)
	local humanoid = char:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			forceResetUI()
		end)
	end
end

if player.Character then
	hookCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
	task.wait(0.2)
	forceResetUI()
	hookCharacter(char)
end)

-- =====================================================================
-- CLOSE ALL TABS
-- =====================================================================
function OpenFrame.CloseAll()
	local tabsFolder = getTabsFolder()
	if not tabsFolder then return end

	local black = tabsFolder:FindFirstChild("Black")

	for _, frame in ipairs(tabsFolder:GetChildren()) do
		if frame:IsA("GuiObject")
			and frame.Name ~= "Black"
			and frame.Name ~= SKIP_TAB_NAME
			and frame.Visible
		then
			UIEffects.close(frame)
		end
	end

	if black and black.Visible then
		TweenService:Create(black, BLACK_FADE_OUT, { BackgroundTransparency = 1 }):Play()
		task.delay(BLACK_FADE_OUT.Time, function()
			black.Visible = false
			black.BackgroundTransparency = 0.5
		end)
	end

	local blur = Lighting:FindFirstChild("Blur")
	if blur then
		blur.Enabled = false
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	local screenGui = playerGui and (playerGui:FindFirstChild("ScreenGui") or playerGui:FindFirstChild("Menus"))
	local carrying = screenGui and screenGui:FindFirstChild("Carrying")
	if not (carrying and carrying.Visible) then
		setScreenGuiVisible(true)
	end
end

-- =====================================================================
-- TOGGLE FRAME
-- =====================================================================
function OpenFrame.ToggleFrame(buttonOrName)
	local tabsFolder = getTabsFolder()
	if not tabsFolder then
		warn("OpenFrame: Tabs folder not found in PlayerGui or PlayerGui.Menus")
		return
	end

	local frameName

	if typeof(buttonOrName) == "string" then
		frameName = buttonOrName
	elseif typeof(buttonOrName) == "Instance" then
		frameName = buttonOrName.Name
		local frameNameValue = buttonOrName:FindFirstChild("FrameName")
		if frameNameValue and frameNameValue:IsA("StringValue") then
			frameName = frameNameValue.Value
		end
	else
		warn("OpenFrame: ToggleFrame expects Button instance or frame name string")
		return
	end

	local targetFrame = tabsFolder:FindFirstChild(frameName)
	if not targetFrame then
		warn("OpenFrame: No matching frame in Tabs for:", frameName)
		return
	end

	local black = tabsFolder:FindFirstChild("Black")

	-- CLOSE IF OPEN
	if targetFrame.Visible then
		UIEffects.close(targetFrame, { blur = true })

		if black then
			TweenService:Create(black, BLACK_FADE_OUT, { BackgroundTransparency = 1 }):Play()
			task.delay(BLACK_FADE_OUT.Time, function()
				black.Visible = false
				black.BackgroundTransparency = 0.5
			end)
		end

		local playerGui = player:FindFirstChild("PlayerGui")
		local screenGui = playerGui and (playerGui:FindFirstChild("ScreenGui") or playerGui:FindFirstChild("Menus"))
		local carrying = screenGui and screenGui:FindFirstChild("Carrying")
		if not (carrying and carrying.Visible) then
			setScreenGuiVisible(true)
		end

		return
	end

	-- OPEN FRAME
	for _, frame in ipairs(tabsFolder:GetChildren()) do
		if frame:IsA("GuiObject")
			and frame.Name ~= "Black"
			and frame.Name ~= SKIP_TAB_NAME
		then
			frame.Visible = false
			local s, targetScale = UIEffects.ensureUIScale(frame)
			if s then
				s.Scale = targetScale
			end
		end
	end

	if black then
		black.Visible = true
		black.BackgroundTransparency = 1
		TweenService:Create(black, BLACK_FADE_IN, { BackgroundTransparency = 0.5 }):Play()
	end

	setScreenGuiVisible(false)

	UIEffects.open(targetFrame, { blur = true })
end

return OpenFrame
