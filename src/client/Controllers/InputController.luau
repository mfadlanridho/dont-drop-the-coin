--!nonstrict
--[[
    InputController.luau
    Client controller handling E keybind (PC) and Touch Button (Mobile/Tablet via ContextActionService) for Dash Bump skill.
    Location: src/client/Controllers/InputController.luau (Syncs to StarterPlayerScripts.Client.Controllers.InputController)
--]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))

local ACTION_DASH_BUMP = "DashBumpAction"
local lastCastTime = 0
local localPlayer = Players.LocalPlayer

local InputController = {}

-- Cast Dash Bump Ability
local function triggerDashBump()
	local now = os.clock()
	if (now - lastCastTime) < Config.BUMP_COOLDOWN then
		return
	end

	-- Simple guard check
	if not PlayerFSM.CanDash(localPlayer) then
		return
	end

	lastCastTime = now

	-- Fire Server Remote (Server manages state transition & attribute replication)
	local bumpEvent = Remotes.Get("DashBump")
	if bumpEvent then
		bumpEvent:FireServer()
	end
end

-- ContextActionService Handler
local function handleAction(actionName, inputState, inputObject)
	if actionName == ACTION_DASH_BUMP and inputState == Enum.UserInputState.Begin then
		triggerDashBump()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

function InputController.Init()
	-- Bind E Key (PC) and Create Touch Button (Mobile)
	ContextActionService:BindAction(
		ACTION_DASH_BUMP,
		handleAction,
		true, -- Create mobile touch button automatically!
		Enum.KeyCode.E
	)

	-- Set Mobile Button Title & Position
	ContextActionService:SetTitle(ACTION_DASH_BUMP, "DASH BUMP")
	ContextActionService:SetDescription(ACTION_DASH_BUMP, "Knockback opponents!")

	print("[InputController] Dash Bump input keybinds initialized.")
end

return InputController
