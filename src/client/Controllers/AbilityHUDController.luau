--!strict
--[[
    AbilityHUDController.luau
    Client controller binding inputs, live radial countdown sweeps, and active glow VFX
    to the pre-built StarterGui.MainHUD.AbilitiesContainer.
    Location: src/client/Controllers/AbilityHUDController.luau (Syncs to StarterPlayerScripts.Client.Controllers.AbilityHUDController)
	INGORE FOR NOW, TODO LATER BY THE DEV IF SPECIFIED: Remove bounceButton.
--]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))

local LocalPlayer = Players.LocalPlayer

local ACTION_CAST_SLOT1 = "Ability_CastSlot1"
local ACTION_CAST_SLOT2 = "Ability_CastSlot2"

type SlotState = {
	AbilityId: string,
	Button: ImageButton,
	Glow: UIStroke,
	Overlay: Frame,
	Label: TextLabel,
	KeyBadge: Frame?,
	CooldownDuration: number,
	ActiveDuration: number,
	CooldownExpiresAt: number,
	ActiveExpiresAt: number,
}

local slots: { [string]: SlotState } = {}
local isBound = false

local AbilityHUDController = {}

--- Triggers an ability by ID if the player is in a valid state
local function castAbility(abilityId: string)
	if PlayerFSM.GetState(LocalPlayer) ~= "Normal" then
		return
	end

	local slot = slots[abilityId]
	if slot and os.clock() < slot.CooldownExpiresAt then
		return -- On cooldown
	end

	local useAbilityRemote = Remotes.Get("UseAbility")
	if useAbilityRemote then
		useAbilityRemote:FireServer(abilityId)
	end
end

--- Plays a subtle press bounce animation on a slot button
local function bounceButton(button: ImageButton)
	local tweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
	local tween = TweenService:Create(button, tweenInfo, {
		Size = UDim2.new(0, 50, 0, 50),
	})
	tween:Play()
end

--- Updates the visual countdowns and glow states for all slots
local function updateSlotVisuals()
	local now = os.clock()

	for _, slot in pairs(slots) do
		local cdRemaining = math.max(0, slot.CooldownExpiresAt - now)
		local activeRemaining = math.max(0, slot.ActiveExpiresAt - now)

		-- Active Glow state
		if activeRemaining > 0 then
			slot.Glow.Enabled = true
		else
			slot.Glow.Enabled = false
		end

		-- Cooldown Overlay state
		if cdRemaining > 0 then
			slot.Overlay.Visible = true
			if cdRemaining >= 10 then
				slot.Label.Text = string.format("%d", math.ceil(cdRemaining))
			else
				slot.Label.Text = string.format("%.1f", cdRemaining)
			end
		else
			slot.Overlay.Visible = false
		end
	end
end

--- Binds to the pre-built AbilitiesContainer inside MainHUD
local function bindAbilitiesHUD()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local mainHud = playerGui:WaitForChild("MainHUD", 10) :: ScreenGui?
	if not mainHud then return end

	local container = mainHud:WaitForChild("AbilitiesContainer", 10) :: Frame?
	if not container then return end

	local isKeyboard = UserInputService.KeyboardEnabled

	-- Slot 1: Speed Surge (Q)
	local slot1Btn = container:WaitForChild("Slot1", 5) :: ImageButton?
	if slot1Btn then
		local glow = slot1Btn:WaitForChild("ActiveGlow", 5) :: UIStroke
		local overlay = slot1Btn:WaitForChild("CooldownOverlay", 5) :: Frame
		local label = overlay:WaitForChild("CountdownLabel", 5) :: TextLabel
		local keyBadge = slot1Btn:FindFirstChild("KeybindBadge") :: Frame?

		if keyBadge then
			keyBadge.Visible = isKeyboard
		end

		slots["speed_surge"] = {
			AbilityId = "speed_surge",
			Button = slot1Btn,
			Glow = glow,
			Overlay = overlay,
			Label = label,
			KeyBadge = keyBadge,
			CooldownDuration = 15,
			ActiveDuration = 5,
			CooldownExpiresAt = 0,
			ActiveExpiresAt = 0,
		}

		slot1Btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				bounceButton(slot1Btn)
				castAbility("speed_surge")
			end
		end)
	end

	-- Slot 2: Super Spring (F)
	local slot2Btn = container:WaitForChild("Slot2", 5) :: ImageButton?
	if slot2Btn then
		local glow = slot2Btn:WaitForChild("ActiveGlow", 5) :: UIStroke
		local overlay = slot2Btn:WaitForChild("CooldownOverlay", 5) :: Frame
		local label = overlay:WaitForChild("CountdownLabel", 5) :: TextLabel
		local keyBadge = slot2Btn:FindFirstChild("KeybindBadge") :: Frame?

		if keyBadge then
			keyBadge.Visible = isKeyboard
		end

		slots["super_spring"] = {
			AbilityId = "super_spring",
			Button = slot2Btn,
			Glow = glow,
			Overlay = overlay,
			Label = label,
			KeyBadge = keyBadge,
			CooldownDuration = 12,
			ActiveDuration = 4,
			CooldownExpiresAt = 0,
			ActiveExpiresAt = 0,
		}

		slot2Btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				bounceButton(slot2Btn)
				castAbility("super_spring")
			end
		end)
	end
end

function AbilityHUDController.Init()
	if isBound then return end
	isBound = true

	-- Bind PC Keybinds
	ContextActionService:BindAction(
		ACTION_CAST_SLOT1,
		function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				castAbility("speed_surge")
				local slot = slots["speed_surge"]
				if slot then bounceButton(slot.Button) end
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.KeyCode.Q
	)

	ContextActionService:BindAction(
		ACTION_CAST_SLOT2,
		function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				castAbility("super_spring")
				local slot = slots["super_spring"]
				if slot then bounceButton(slot.Button) end
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.KeyCode.F
	)

	-- Listen for server cooldown/duration replication
	local updateAbilityRemote = Remotes.Get("UpdateAbilityState")
	if updateAbilityRemote then
		updateAbilityRemote.OnClientEvent:Connect(function(abilityId: string, cdDuration: number, duration: number)
			local slot = slots[abilityId]
			if slot then
				local now = os.clock()
				slot.CooldownDuration = cdDuration or 10
				slot.ActiveDuration = duration or 0
				slot.CooldownExpiresAt = now + slot.CooldownDuration
				slot.ActiveExpiresAt = now + slot.ActiveDuration
				updateSlotVisuals()
			end
		end)
	end

	-- Initial GUI bind
	task.spawn(bindAbilitiesHUD)

	-- Re-bind on GUI reload / respawn
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "MainHUD" then
			task.spawn(bindAbilitiesHUD)
		end
	end)

	-- Smooth local ticker (10Hz)
	task.spawn(function()
		while true do
			task.wait(0.08)
			updateSlotVisuals()
		end
	end)

	print("[AbilityHUDController] Initialized Abilities Action Bar HUD (Slot 1: Q, Slot 2: F).")
end

return AbilityHUDController
