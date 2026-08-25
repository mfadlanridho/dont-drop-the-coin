-- ButtonFunctionality Module
-- Micro-interaction system for buttons (hover, click, sounds, multi-device support)
-- Place in: src/shared/UI/ButtonFunctionality.luau -> ReplicatedStorage.Shared.UI.ButtonFunctionality

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local ButtonFunctionality = {}

-- =========================
-- CONFIG
-- =========================

local DEFAULT_HOVER_SCALE = 1.03
local DEFAULT_CLICK_SCALE = 0.97
local DEFAULT_NORMAL_SCALE = 1

local TWEEN_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- =========================
-- SOUNDS
-- =========================

local hoverSound, clickSound
local soundsLoaded = false

local function loadSounds()
	if soundsLoaded then return end

	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	local sounds = (sharedFolder and sharedFolder:FindFirstChild("Sounds")) or ReplicatedStorage:FindFirstChild("Sounds")
	if sounds then
		local guiSounds = sounds:FindFirstChild("GuisSounds")
		if guiSounds then
			hoverSound = guiSounds:FindFirstChild("Hover")
			clickSound = guiSounds:FindFirstChild("Click")
		end
	end

	soundsLoaded = true
end

local function playSound(sound)
	if not sound then return end
	local s = sound:Clone()
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
end

-- =========================
-- TWEEN TRACKING (SAFE)
-- =========================

local ActiveTweens = setmetatable({}, { __mode = "k" }) -- weak keys

local function tweenScale(uiScale, tweenInfo, scale)
	local oldTween = ActiveTweens[uiScale]
	if oldTween then
		oldTween:Cancel()
	end

	local t = TweenService:Create(uiScale, tweenInfo, { Scale = scale })
	ActiveTweens[uiScale] = t
	t:Play()
end

-- =========================
-- SETUP BUTTON
-- =========================

function ButtonFunctionality.SetupButton(button, uiScale, config)
	if not button or not button:IsA("GuiObject") then
		warn("ButtonFunctionality: Invalid GuiObject")
		return nil
	end

	if button:IsA("Frame") then
		button.Active = true
	end

	loadSounds()

	config = config or {}

	local hoverScale = config.hoverScale or DEFAULT_HOVER_SCALE
	local clickScale = config.clickScale or DEFAULT_CLICK_SCALE
	local normalScale = config.normalScale or DEFAULT_NORMAL_SCALE

	local playHoverSoundEnabled = config.playHoverSound ~= false
	local playClickSoundEnabled = config.playClickSound ~= false
	local onClickCallback = config.onClickCallback

	-- =========================
	-- UISCALE (ON BUTTON ITSELF)
	-- =========================

	if not uiScale then
		uiScale = button:FindFirstChildOfClass("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Scale = normalScale
			uiScale.Parent = button
		end
	end

	-- =========================
	-- STATE
	-- =========================

	local hovering = false
	local pressed = false
	local selected = false

	-- =========================
	-- HOVER (MOUSE ONLY)
	-- =========================

	if UserInputService.MouseEnabled then
		button.MouseEnter:Connect(function()
			hovering = true
			if playHoverSoundEnabled then
				playSound(hoverSound)
			end
			if not pressed then
				tweenScale(uiScale, TWEEN_SMOOTH, hoverScale)
			end
		end)

		button.MouseLeave:Connect(function()
			hovering = false
			if not pressed and not selected then
				tweenScale(uiScale, TWEEN_SMOOTH, normalScale)
			end
		end)
	end

	-- =========================
	-- GAMEPAD / VR SELECTION
	-- =========================

	button.SelectionGained:Connect(function()
		selected = true
		if playHoverSoundEnabled then
			playSound(hoverSound)
		end
		if not pressed then
			tweenScale(uiScale, TWEEN_SMOOTH, hoverScale)
		end
	end)

	button.SelectionLost:Connect(function()
		selected = false
		if not pressed and not hovering then
			tweenScale(uiScale, TWEEN_SMOOTH, normalScale)
		end
	end)

	-- =========================
	-- PRESS (ALL DEVICES SAFE)
	-- =========================

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.Gamepad1 then

			pressed = true
			if playClickSoundEnabled then
				playSound(clickSound)
			end
			tweenScale(uiScale, TWEEN_FAST, clickScale)
		end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.Gamepad1 then

			pressed = false
			local target = (hovering or selected) and hoverScale or normalScale
			tweenScale(uiScale, TWEEN_SMOOTH, target)
		end
	end)

	-- =========================
	-- SAFETY RESET IF UI REMOVED
	-- =========================

	button.AncestryChanged:Connect(function(_, parent)
		if not parent then
			if uiScale then
				uiScale.Scale = normalScale
			end
		end
	end)

	-- =========================
	-- ACTUAL CLICK
	-- =========================

	if onClickCallback then
		local lastClickTime = 0
		local function triggerCallback()
			local now = os.clock()
			if (now - lastClickTime) < 0.25 then return end
			lastClickTime = now
			onClickCallback()
		end

		if button:IsA("GuiButton") then
			button.Activated:Connect(triggerCallback)
			button.MouseButton1Click:Connect(triggerCallback)
		else
			button.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
					or input.UserInputType == Enum.UserInputType.Gamepad1 then
					triggerCallback()
				end
			end)
		end
	end

	return uiScale
end

-- =========================
-- CLEANUP
-- =========================

function ButtonFunctionality.CleanupButton(button, uiScale)
	if button then
		button.Active = false
	end

	if uiScale then
		local oldTween = ActiveTweens[uiScale]
		if oldTween then
			oldTween:Cancel()
		end
		uiScale.Scale = DEFAULT_NORMAL_SCALE
	end
end

return ButtonFunctionality
