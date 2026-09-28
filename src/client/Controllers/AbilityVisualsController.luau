--!strict
--[[
    AbilityVisualsController.luau
    Client controller managing dynamic camera speed FOV, character speed motion blur trails,
    jump shockwave VFX, Top Active Buffs HUD banner, and 3D Overhead Buff Indicators (BillboardGui).
    Location: src/client/Controllers/AbilityVisualsController.luau (Syncs to StarterPlayerScripts.Client.Controllers.AbilityVisualsController)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

type ActiveBuffState = {
	AbilityId: string,
	Duration: number,
	ExpiresAt: number,
	Icon: string,
	OverheadPill: Frame?,
	OverheadLabel: TextLabel?,
}

local activeBuffs: { [string]: ActiveBuffState } = {}
local currentOverheadGui: BillboardGui? = nil
local speedTrail: Trail? = nil
local originalFOV = 70
local isFOVExpanded = false

local AbilityVisualsController = {}

--- Tweens Camera FieldOfView
local function setCameraFOV(targetFOV: number, duration: number?)
	if not Camera then return end
	local tweenInfo = TweenInfo.new(duration or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(Camera, tweenInfo, {
		FieldOfView = targetFOV,
	})
	tween:Play()
end

--- Ensures speed trail attachments are present on character
local function setupSpeedTrail(character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hrp then return end

	-- Clean up existing
	local oldTrail = hrp:FindFirstChild("SpeedSurgeTrail")
	if oldTrail then oldTrail:Destroy() end

	local att0 = hrp:FindFirstChild("TrailAtt0") :: Attachment?
	if not att0 then
		att0 = Instance.new("Attachment")
		att0.Name = "TrailAtt0"
		att0.Position = Vector3.new(0, -1.2, 0)
		att0.Parent = hrp
	end

	local att1 = hrp:FindFirstChild("TrailAtt1") :: Attachment?
	if not att1 then
		att1 = Instance.new("Attachment")
		att1.Name = "TrailAtt1"
		att1.Position = Vector3.new(0, 1.2, 0)
		att1.Parent = hrp
	end

	local trail = Instance.new("Trail")
	trail.Name = "SpeedSurgeTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.3
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 240, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Enabled = false
	trail.Parent = hrp

	speedTrail = trail
end

--- Applies icon (either Image asset or Text emoji) to a buff pill
local function applyIconToPill(pill: Frame, icon: string)
	local iconLabel = pill:FindFirstChild("IconLabel") :: TextLabel?
	local iconImage = pill:FindFirstChild("IconImage") :: ImageLabel?

	local isImageAsset = string.find(icon, "rbxassetid://") ~= nil
		or string.find(icon, "http") ~= nil
		or string.find(icon, "rbxasset://") ~= nil

	if isImageAsset then
		if iconImage then
			iconImage.Image = icon
			iconImage.Visible = true
		end
		if iconLabel then
			iconLabel.Visible = false
		end
	else
		if iconLabel then
			iconLabel.Text = icon
			iconLabel.Visible = true
		end
		if iconImage then
			iconImage.Visible = false
		end
	end
end

--- Clones the pre-built 3D Overhead Buff BillboardGui template for a character
local function setupOverheadBuffGui(character: Model): BillboardGui?
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hrp then return nil end

	local existing = hrp:FindFirstChild("OverheadBuffGui") :: BillboardGui?
	if existing then existing:Destroy() end

	local templates = ReplicatedStorage:FindFirstChild("Templates")
	local templateBbg = templates and templates:FindFirstChild("OverheadBuffGui") :: BillboardGui?
	if not templateBbg then
		warn("[AbilityVisualsController] ReplicatedStorage.Templates.OverheadBuffGui template not found!")
		return nil
	end

	local bbg = templateBbg:Clone()
	bbg.Adornee = hrp
	bbg.Parent = hrp
	currentOverheadGui = bbg

	-- Re-bind any currently active buffs to new pills in the new character's OverheadBuffGui
	local now = os.clock()
	local pillTemplate = bbg:FindFirstChild("BuffPillTemplate") :: Frame?
	if pillTemplate then
		for abilityId, buff in pairs(activeBuffs) do
			if buff.ExpiresAt > now then
				local pill = pillTemplate:Clone()
				pill.Name = abilityId .. "_Pill"
				applyIconToPill(pill, buff.Icon)
				local timerLabel = pill:FindFirstChild("TimerLabel") :: TextLabel?
				pill.Visible = true
				pill.Size = UDim2.new(0, 44, 0, 60)
				pill.Parent = bbg
				buff.OverheadPill = pill
				buff.OverheadLabel = timerLabel
			end
		end
	end

	return bbg
end

--- Emits an emerald upward jump ring shockwave at character feet
local function emitJumpShockwave(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local ring = Instance.new("Part")
	ring.Name = "JumpShockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(0, 255, 120)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Transparency = 0.2
	ring.Parent = Workspace

	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(ring, tweenInfo, {
		Size = Vector3.new(0.1, 14, 14),
		Transparency = 1,
	})
	tween:Play()
	task.delay(0.45, function()
		ring:Destroy()
	end)
end

--- Shows an overhead badge with bounce pop-in animation
local function showBuffVisuals(buff: ActiveBuffState)
	if buff.OverheadPill then
		buff.OverheadPill.Visible = true
		buff.OverheadPill.Size = UDim2.new(0, 0, 0, 0)
		local tween = TweenService:Create(buff.OverheadPill, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 44, 0, 60),
		})
		tween:Play()
	end
end

--- Hides an overhead badge with smooth shrink animation
local function hideBuffVisuals(buff: ActiveBuffState)
	if buff.OverheadPill and buff.OverheadPill.Visible then
		local tween = TweenService:Create(buff.OverheadPill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
		})
		tween:Play()
		task.delay(0.2, function()
			if buff.ExpiresAt <= os.clock() and buff.OverheadPill then
				buff.OverheadPill.Visible = false
			end
		end)
	end
end

function AbilityVisualsController.Init()
	-- Setup trails & 3D overhead BillboardGui on character spawn
	local function onCharacter(char: Model)
		task.spawn(setupSpeedTrail, char)
		task.spawn(setupOverheadBuffGui, char)
	end

	if LocalPlayer.Character then
		onCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(onCharacter)

	-- Listen for Ability Activations
	local updateAbilityRemote = Remotes.Get("UpdateAbilityState")
	if updateAbilityRemote then
		updateAbilityRemote.OnClientEvent:Connect(function(abilityId: string, cdDuration: number, duration: number, icon: string?)
			local now = os.clock()
			local buffDuration = duration or 4
			local abilityIcon = icon or "⚡"

			local buff = activeBuffs[abilityId]
			if not buff then
				buff = {
					AbilityId = abilityId,
					Duration = buffDuration,
					ExpiresAt = now + buffDuration,
					Icon = abilityIcon,
					OverheadPill = nil,
					OverheadLabel = nil,
				}
				activeBuffs[abilityId] = buff
			else
				buff.Duration = buffDuration
				buff.ExpiresAt = now + buffDuration
				buff.Icon = abilityIcon
			end

			-- Ensure pill exists in current OverheadBuffGui
			if currentOverheadGui and (not buff.OverheadPill or not buff.OverheadPill.Parent) then
				local pillTemplate = currentOverheadGui:FindFirstChild("BuffPillTemplate") :: Frame?
				if pillTemplate then
					local pill = pillTemplate:Clone()
					pill.Name = abilityId .. "_Pill"
					applyIconToPill(pill, buff.Icon)
					local timerLabel = pill:FindFirstChild("TimerLabel") :: TextLabel?
					pill.Parent = currentOverheadGui
					buff.OverheadPill = pill
					buff.OverheadLabel = timerLabel
				end
			end

			-- 1. Show Overhead 3D Badge
			showBuffVisuals(buff)

			-- 2. Trigger Specific Visual Layers
			if abilityId == "speed_surge" then
				if not isFOVExpanded then
					isFOVExpanded = true
					setCameraFOV(82, 0.3)
				end
				if speedTrail then
					speedTrail.Enabled = true
				end
			elseif abilityId == "super_spring" then
				if LocalPlayer.Character then
					emitJumpShockwave(LocalPlayer.Character)
				end
			end
		end)
	end

	-- Run continuous smooth ticker for all active overhead badges, FOV reset, and trail shutoff
	task.spawn(function()
		while true do
			task.wait(0.05)
			local now = os.clock()

			for abilityId, buff in pairs(activeBuffs) do
				if buff.ExpiresAt > 0 then
					local remaining = math.max(0, buff.ExpiresAt - now)
					if remaining > 0 then
						if buff.OverheadLabel then
							buff.OverheadLabel.Text = string.format("%.1fs", remaining)
						end
					else
						buff.ExpiresAt = 0
						hideBuffVisuals(buff)

						if abilityId == "speed_surge" then
							if isFOVExpanded then
								isFOVExpanded = false
								setCameraFOV(originalFOV, 0.4)
							end
							if speedTrail then
								speedTrail.Enabled = false
							end
						end
					end
				end
			end
		end
	end)

	print("[AbilityVisualsController] Initialized Generic Modular 3D Overhead Buff System.")
end

return AbilityVisualsController
