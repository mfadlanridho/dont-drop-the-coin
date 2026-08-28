--!strict
--[[
    GuardAI.luau
    Universal Roblox AI Workspace Guard AI Framework supporting BOTH Humanoid walking NPCs and Non-Humanoid flying drones.
    Location: src/shared/AI/GuardAI.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)
local StateMachine = require(Shared:WaitForChild("Utils"):WaitForChild("StateMachine") :: ModuleScript)

local log = Logger.create("Combat")

local StatesFolder = script.Parent:WaitForChild("States")
local IdleState = require(StatesFolder:WaitForChild("IdleState") :: ModuleScript)
local PatrolState = require(StatesFolder:WaitForChild("PatrolState") :: ModuleScript)
local ChaseState = require(StatesFolder:WaitForChild("ChaseState") :: ModuleScript)
local AttackState = require(StatesFolder:WaitForChild("AttackState") :: ModuleScript)

local GuardAI = {}
GuardAI.__index = GuardAI

export type GuardAIConfig = {
	detectionRadius: number?,
	moveSpeed: number?,
	attackRadius: number?,
	attackRecoveryTime: number?,
	platformPart: BasePart?,
	onAttackHit: ((victimModel: Model) -> ())?,
}

export type GuardAIInstance = {
	model: Model,
	primaryPart: BasePart,
	humanoid: Humanoid?,
	context: any,
	stateMachine: any,
	isDormant: boolean,
	isDestroyed: boolean,
	platformPart: BasePart?,
	activePlayersOnPlatform: { [Player]: number },
	heartbeatConn: RBXScriptConnection?,
	touchConn: RBXScriptConnection?,
}

-- Universal MoveTo Adapter (Handles BOTH Humanoids and Non-Humanoid Drones)
local function universalMoveToPosition(context: any, targetPos: Vector3)
	if context.humanoid then
		-- 1. Humanoid Ground Walking: Native Humanoid:MoveTo()
		context.humanoid.WalkSpeed = context.moveSpeed or 16
		context.humanoid:MoveTo(targetPos)
	else
		-- 2. Non-Humanoid Flying Drones: Smooth 3D flying motion
		local primaryPart = context.primaryPart
		if not primaryPart then return end
		local currentPos = primaryPart.Position
		local moveDir = (targetPos - currentPos)
		if moveDir.Magnitude > 0.1 then
			local stepPos = currentPos + (moveDir.Unit * math.min(moveDir.Magnitude, (context.moveSpeed or 16) * (context.deltaTime or (1/60))))
			primaryPart.CFrame = CFrame.new(stepPos, stepPos + moveDir)
		end
	end
end

function GuardAI.new(model: Model, config: GuardAIConfig?): GuardAIInstance
	local self = setmetatable({}, GuardAI) :: any
	self.model = model
	self.humanoid = model:FindFirstChildWhichIsA("Humanoid")
	self.primaryPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
	self.isDestroyed = false
	self.isDormant = false
	self.activePlayersOnPlatform = {}

	-- Resolve Platform Part
	local resolvedPlatform: BasePart? = config and config.platformPart
	if not resolvedPlatform then
		local attrPart = model:GetAttribute("PlatformPart")
		if typeof(attrPart) == "Instance" and attrPart:IsA("BasePart") then
			resolvedPlatform = attrPart
		elseif model.Parent and model.Parent:IsA("Model") then
			resolvedPlatform = model.Parent:FindFirstChild("PlatformFloor") or model.Parent:FindFirstChildWhichIsA("BasePart")
		end
	end
	self.platformPart = resolvedPlatform

	local primaryPart = self.primaryPart
	local startPos = primaryPart and primaryPart.Position or Vector3.zero

	self.context = {
		model = model,
		primaryPart = primaryPart,
		humanoid = self.humanoid,
		startPos = startPos,
		detectionRadius = config and config.detectionRadius or model:GetAttribute("DetectionRadius") or 40,
		moveSpeed = config and config.moveSpeed or model:GetAttribute("MoveSpeed") or 16,
		attackRadius = config and config.attackRadius or 5.0,
		attackRecoveryTime = config and config.attackRecoveryTime or 0.5,
		onAttackHit = config and config.onAttackHit,
		moveToPosition = universalMoveToPosition,
		currentTargetHrp = nil,
		lastTargetTime = 0,
		patrolStartTime = 0,
		isAttacking = false,
		isDormant = false,
	}

	self:init()
	return self
end

function GuardAI:init()
	if not self.primaryPart then return end
	if not self.humanoid then
		self.primaryPart.Anchored = true
	end

	-- Touch listener for direct physical contact
	self.touchConn = self.primaryPart.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if player and self.context.onAttackHit then
			log(string.format("[GuardAI] %s physical touch hit on player %s!", self.model.Name, player.Name))
			self.context.onAttackHit(character)
		end
	end)

	-- Platform Occupancy Listener
	if self.platformPart then
		self.isDormant = true
		self.context.isDormant = true
		log(string.format("[GuardAI] %s bound to platform %s (Initialized Dormant)", self.model.Name, self.platformPart.Name))

		local platform = self.platformPart
		platform.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then return end
			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end

			local currentCount = self.activePlayersOnPlatform[player] or 0
			self.activePlayersOnPlatform[player] = currentCount + 1

			if currentCount == 0 and self.isDormant then
				self.isDormant = false
				self.context.isDormant = false
				log(string.format("[GuardAI] %s WOKE UP! Player %s entered platform %s.", self.model.Name, player.Name, platform.Name))
			end
		end)

		platform.TouchEnded:Connect(function(hit)
			local character = hit.Parent
			if not character then return end
			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end

			local currentCount = self.activePlayersOnPlatform[player] or 0
			if currentCount > 0 then
				currentCount -= 1
				if currentCount == 0 then
					self.activePlayersOnPlatform[player] = nil
				else
					self.activePlayersOnPlatform[player] = currentCount
				end
			end

			if next(self.activePlayersOnPlatform) == nil and not self.isDormant then
				self.isDormant = true
				self.context.isDormant = true
				self.context.currentTargetHrp = nil
				if self.stateMachine then
					self.stateMachine:setState("Patrol", self.context)
				end
				log(string.format("[GuardAI] %s exiting platform %s -> Returning home via PatrolState.", self.model.Name, platform.Name))
			end
		end)
	end

	-- Initialize FSM StateMachine with generic states
	self.stateMachine = StateMachine.new(function(oldState, newState)
		log(string.format("[GuardAI] %s transitioned: %s -> %s", self.model.Name, tostring(oldState), tostring(newState)))
	end)

	self.stateMachine:registerState(IdleState)
	self.stateMachine:registerState(PatrolState)
	self.stateMachine:registerState(ChaseState)
	self.stateMachine:registerState(AttackState)

	-- Start FSM in Idle State
	self.stateMachine:setState("Idle", self.context)

	-- Main Heartbeat Loop executing FSM state updates
	self.heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if self.isDestroyed or not self.primaryPart or not self.primaryPart.Parent then
			self:destroy()
			return
		end

		self.context.deltaTime = dt
		self.stateMachine:update(self.context)
	end)
end

function GuardAI:destroy()
	self.isDestroyed = true
	if self.heartbeatConn then
		self.heartbeatConn:Disconnect()
		self.heartbeatConn = nil
	end
	if self.touchConn then
		self.touchConn:Disconnect()
		self.touchConn = nil
	end
end

return GuardAI
