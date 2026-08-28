--!strict
--[[
    GuardAI.luau
    Generic, highly reusable OOP class for NPC Guard/Monster AIs using StateMachine FSM pattern.
    Completely project-agnostic for reuse across future Roblox games.
    Location: src/server/NPCAI/GuardAI.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)
local StateMachine = require(Shared:WaitForChild("Utils"):WaitForChild("StateMachine") :: ModuleScript)

local log = Logger.create("Combat")

local StatesFolder = script.Parent:WaitForChild("States")
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
	onAttackHit: ((victimModel: Model) -> ())?,
}

export type GuardAIInstance = {
	model: Model,
	primaryPart: BasePart,
	context: any,
	stateMachine: any,
	isDestroyed: boolean,
	heartbeatConn: RBXScriptConnection?,
	touchConn: RBXScriptConnection?,
}

function GuardAI.new(model: Model, config: GuardAIConfig?): GuardAIInstance
	local self = setmetatable({}, GuardAI) :: any
	self.model = model
	self.primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	self.isDestroyed = false

	local primaryPart = self.primaryPart
	local startPos = primaryPart and primaryPart.Position or Vector3.zero

	self.context = {
		model = model,
		primaryPart = primaryPart,
		startPos = startPos,
		detectionRadius = config and config.detectionRadius or 40,
		moveSpeed = config and config.moveSpeed or 16,
		attackRadius = config and config.attackRadius or 5.0,
		attackRecoveryTime = config and config.attackRecoveryTime or 0.5,
		onAttackHit = config and config.onAttackHit,
		currentTargetHrp = nil,
		lastTargetTime = 0,
		patrolStartTime = 0,
		isAttacking = false,
	}

	self:init()
	return self
end

function GuardAI:init()
	if not self.primaryPart then return end
	self.primaryPart.Anchored = true

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

	-- Initialize FSM StateMachine with generic states
	self.stateMachine = StateMachine.new(function(oldState, newState)
		log(string.format("[GuardAI] %s transitioned: %s -> %s", self.model.Name, tostring(oldState), tostring(newState)))
	end)

	self.stateMachine:registerState(PatrolState)
	self.stateMachine:registerState(ChaseState)
	self.stateMachine:registerState(AttackState)

	-- Start FSM in Patrol State
	self.stateMachine:setState("Patrol", self.context)

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
