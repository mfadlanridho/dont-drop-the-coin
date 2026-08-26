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
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger"))

local debugLog = Logger.create("Input")

local ACTION_DASH_BUMP = "DashBumpAction"
local lastCastTime = 0
local localPlayer = Players.LocalPlayer

local InputController = {}

-- Find closest opponent player within 15-stud forward dash path on client
local function findTargetVictimOnClient(): Player?
	local char = localPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return nil end

	local origin = hrp.Position
	local lookDir = hrp.CFrame.LookVector
	local closestVictim: Player? = nil
	local minDistance = Config.DASH_DISTANCE + 4.5

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= localPlayer and otherPlayer.Character then
			local victimHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart") :: Part
			if victimHrp then
				local toVictim = victimHrp.Position - origin
				local forwardDist = toVictim:Dot(lookDir)
				local lateralDist = (toVictim - (lookDir * forwardDist)).Magnitude

				if forwardDist > 0 and forwardDist <= minDistance and lateralDist <= 5.5 then
					closestVictim = otherPlayer
					minDistance = forwardDist
				end
			end
		end
	end

	return closestVictim
end

-- Cast Dash Bump Ability
local function triggerDashBump()
	local now = os.clock()
	local timeDiff = now - lastCastTime
	local canDashState = PlayerFSM.CanDash(localPlayer)
	local currentState = PlayerFSM.GetState(localPlayer)

	debugLog(string.format("triggerDashBump invoked | State: %s | CanDash: %s | TimeSinceLastCast: %.2fs", tostring(currentState), tostring(canDashState), timeDiff))

	if timeDiff < Config.BUMP_COOLDOWN then
		debugLog(string.format("Dash blocked by local cooldown (Remaining: %.2fs)", Config.BUMP_COOLDOWN - timeDiff))
		return
	end

	if not canDashState then
		debugLog(string.format("Dash blocked by FSM state: %s", tostring(currentState)))
		return
	end

	lastCastTime = now

	-- Perform instant local target validation check
	local targetVictim = findTargetVictimOnClient()
	if targetVictim then
		debugLog(string.format("Client detected target victim: %s", targetVictim.Name))
	end

	-- Fire Server Remote
	local bumpEvent = Remotes.Get("DashBump")
	if bumpEvent then
		debugLog("Firing DashBump remote event to Server...")
		bumpEvent:FireServer(targetVictim)
	else
		warn("[InputController] ERROR: DashBump RemoteEvent not found!")
	end
end

-- ContextActionService Handler
local function handleAction(actionName, inputState, inputObject)
	if actionName == ACTION_DASH_BUMP and inputState == Enum.UserInputState.Begin then
		debugLog("Keybind E pressed by user!")
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
		true,
		Enum.KeyCode.E
	)

	ContextActionService:SetTitle(ACTION_DASH_BUMP, "DASH BUMP")
	ContextActionService:SetDescription(ACTION_DASH_BUMP, "Knockback opponents!")

	debugLog("Dash Bump input keybinds initialized.")
end

return InputController
