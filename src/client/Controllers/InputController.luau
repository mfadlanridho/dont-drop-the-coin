--!nonstrict
--[[
    InputController.luau
    Client controller handling E keybind (PC), interactive Touch/Click button on MainHUD.CooldownContainer,
    and real-time cooldown countdown display.
    Location: src/client/Controllers/InputController.luau (Syncs to StarterPlayerScripts.Client.Controllers.InputController)
--]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))
local Logger = require(Packages:WaitForChild("LoggerModule"))

local debugLog = Logger.create("Input")

local ACTION_DASH_BUMP = "DashBumpAction"
local lastCastTime = 0
local localPlayer = Players.LocalPlayer

-- Active UI references
local cooldownFrame: ImageLabel? = nil
local innerIcon: ImageLabel? = nil
local textLabel: TextLabel? = nil

local InputController = {}

-- Updates visual state of the Cooldown button based on remaining time
local function updateCooldownVisuals()
	local now = os.clock()
	local elapsed = now - lastCastTime
	local remaining = Config.BUMP_COOLDOWN - elapsed

	if not textLabel then
		return
	end

	if remaining > 0 then
		textLabel.Text = tostring(math.ceil(remaining))
		textLabel.Visible = true
		if innerIcon then
			innerIcon.Visible = true
		end
	else
		if UserInputService.KeyboardEnabled then
			textLabel.Text = "E"
			textLabel.Visible = true
		else
			textLabel.Text = ""
			textLabel.Visible = false
		end
		if innerIcon then
			innerIcon.Visible = false
		end
	end
end

-- Runs the countdown loop when cooldown begins
local function startCooldownCountdown()
	task.spawn(function()
		while true do
			local now = os.clock()
			local remaining = Config.BUMP_COOLDOWN - (now - lastCastTime)
			updateCooldownVisuals()
			if remaining <= 0 then
				break
			end
			task.wait(0.1)
		end
	end)
end

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

	-- Start Visual Cooldown
	startCooldownCountdown()

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

-- Binds MainHUD CooldownContainer button & labels
local function bindMainHUD()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local mainHud = playerGui:WaitForChild("MainHUD", 10) :: ScreenGui?
	if not mainHud then return end

	local cooldownContainer = mainHud:WaitForChild("CooldownContainer", 5) :: Frame?
	if not cooldownContainer then return end

	local frame = cooldownContainer:WaitForChild("Cooldown", 5) :: ImageLabel?
	if not frame then return end

	cooldownFrame = frame
	innerIcon = frame:FindFirstChild("Cooldown") :: ImageLabel?
	textLabel = frame:FindFirstChild("TextLabel") :: TextLabel?

	-- Enable touch/click directly on the designer's existing element
	frame.Active = true
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			triggerDashBump()
		end
	end)

	-- Initialize or resume visual state
	local now = os.clock()
	if (now - lastCastTime) < Config.BUMP_COOLDOWN then
		startCooldownCountdown()
	else
		updateCooldownVisuals()
	end
end

function InputController.Init()
	-- Bind E Key (PC) without CAS mobile button (createTouchButton = false)
	ContextActionService:BindAction(
		ACTION_DASH_BUMP,
		handleAction,
		false,
		Enum.KeyCode.E
	)

	debugLog("Dash Bump input keybinds initialized.")

	-- Bind to MainHUD and handle character respawn / GUI recreation
	task.spawn(bindMainHUD)

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "MainHUD" then
			task.spawn(bindMainHUD)
		end
	end)
end

return InputController
