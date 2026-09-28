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

type AbilityEffect = {
	AbilityId: string,
	onStart: (character: Model, duration: number) -> (),
	onEnd: (character: Model) -> (),
}

type ActiveBuffState = {
	AbilityId: string,
	Duration: number,
	ExpiresAt: number,
	Icon: string,
	OverheadPill: Frame?,
	OverheadLabel: TextLabel?,
}

local activeBuffs: { [string]: ActiveBuffState } = {}
local registeredEffects: { [string]: AbilityEffect } = {}
local currentOverheadGui: BillboardGui? = nil

local AbilityVisualsController = {}

--- Auto-loads all effect modules from Client.AbilityEffects
local function loadAbilityEffects()
	local clientFolder = script.Parent.Parent
	local effectsFolder = clientFolder:WaitForChild("AbilityEffects", 5) :: Folder?
	if not effectsFolder then
		warn("[AbilityVisualsController] AbilityEffects folder not found!")
		return
	end

	for _, child in ipairs(effectsFolder:GetChildren()) do
		if child:IsA("ModuleScript") then
			local success, effectModule = pcall(require, child)
			if success and typeof(effectModule) == "table" and effectModule.AbilityId then
				registeredEffects[effectModule.AbilityId] = effectModule :: AbilityEffect
			else
				warn(string.format("[AbilityVisualsController] Failed to load effect module: %s", child.Name))
			end
		end
	end
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
	-- 1. Auto-load all Ability Effects
	loadAbilityEffects()

	-- 2. Setup 3D overhead BillboardGui on character spawn
	local function onCharacter(char: Model)
		task.spawn(setupOverheadBuffGui, char)
	end

	if LocalPlayer.Character then
		onCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(onCharacter)

	-- 3. Listen for Ability Activations
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

			-- 3a. Show Overhead 3D Badge
			showBuffVisuals(buff)

			-- 3b. Dispatch onStart to Registered Ability Effect Handler
			local effect = registeredEffects[abilityId]
			if effect and typeof(effect.onStart) == "function" and LocalPlayer.Character then
				task.spawn(effect.onStart, LocalPlayer.Character, buffDuration)
			end
		end)
	end

	-- 4. Run continuous smooth ticker for all active overhead badges and duration expiration
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

						-- Dispatch onEnd to Registered Ability Effect Handler
						local effect = registeredEffects[abilityId]
						if effect and typeof(effect.onEnd) == "function" and LocalPlayer.Character then
							task.spawn(effect.onEnd, LocalPlayer.Character)
						end
					end
				end
			end
		end
	end)

	print("[AbilityVisualsController] Initialized Modular Ability Effects & 3D Overhead Buff System.")
end

return AbilityVisualsController
