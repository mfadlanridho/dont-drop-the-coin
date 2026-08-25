-- UIEffects Module
-- Animates frames popping open/closed, background blur, and audio cues
-- Place in: src/shared/UI/UIEffects.luau -> ReplicatedStorage.Shared.UI.UIEffects

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local UIEffects = {}

-- Sounds
local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5) or ReplicatedStorage
local soundsFolder = sharedFolder:FindFirstChild("Sounds") or ReplicatedStorage:FindFirstChild("Sounds")
local soundFolder = soundsFolder and soundsFolder:FindFirstChild("GuisSounds")
local OpenUISound = soundFolder and soundFolder:FindFirstChild("Open_UI")
local CloseUISound = soundFolder and soundFolder:FindFirstChild("UI_Close")

-- Tweens
local OPEN_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)

-- Generation counter to invalidate stale task.delay callbacks from close()
local closeGeneration = {}

local function playSound(soundObject, parent)
	if not soundObject then return end
	local s = soundObject:Clone()
	s.Parent = parent or game:GetService("SoundService")
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
end

local function ensureUIScale(frame: GuiObject): (UIScale, number)
	local scale = frame:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = frame
	end
	
	local targetScale = scale:GetAttribute("TargetScale")
		or frame:GetAttribute("TargetScale")
		or (scale.Scale > 0 and scale.Scale or 1)
		
	scale:SetAttribute("TargetScale", targetScale)
	return scale, targetScale
end

UIEffects.ensureUIScale = ensureUIScale

function UIEffects.open(frame: GuiObject, options)
	options = options or {}
	
	-- Bump generation so any pending close callback for this frame is invalidated
	closeGeneration[frame] = (closeGeneration[frame] or 0) + 1
	
	local scale, targetScale = ensureUIScale(frame)
	if options.scale then
		targetScale = options.scale
	end
	frame.Visible = true
	
	-- Animate In
	scale.Scale = 0
	TweenService:Create(scale, OPEN_TWEEN_INFO, { Scale = targetScale }):Play()
	
	-- Sound
	playSound(OpenUISound, frame)
	
	-- Blur
	if options.blur then
		local blur = Lighting:FindFirstChild("Blur")
		if blur then
			blur.Enabled = true
		end
	end
end

function UIEffects.close(frame: GuiObject, options)
	options = options or {}
	
	-- Bump generation for this frame
	local gen = (closeGeneration[frame] or 0) + 1
	closeGeneration[frame] = gen
	
	local scale = frame:FindFirstChildOfClass("UIScale")
	if scale then
		local targetScale = scale:GetAttribute("TargetScale") or frame:GetAttribute("TargetScale") or 1
		TweenService:Create(scale, CLOSE_TWEEN_INFO, { Scale = 0 }):Play()
		task.delay(CLOSE_TWEEN_INFO.Time, function()
			-- Only apply if no newer close/open/cancel has occurred
			if closeGeneration[frame] == gen then
				frame.Visible = false
				scale.Scale = targetScale
			end
		end)
	else
		frame.Visible = false
	end
	
	-- Sound
	playSound(CloseUISound, frame)
	
	-- Blur
	if options.blur then
		local blur = Lighting:FindFirstChild("Blur")
		if blur then
			blur.Enabled = false
		end
	end
end

-- Invalidate all pending close callbacks (called by forceResetUI)
function UIEffects.cancelPendingCloses()
	for frame, _ in pairs(closeGeneration) do
		closeGeneration[frame] = (closeGeneration[frame] or 0) + 1
	end
end

return UIEffects
