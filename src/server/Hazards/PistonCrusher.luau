--!nonstrict
--[[
    PistonCrusher.luau
    Modular OOP component for Zone 2 mechanical Piston Crushers.
    Periodically telegraphs with anticipation jitter, slams down with kinematic velocity,
    and smoothly retracts. Triggers outward squash knockback, 2.5s ragdoll, and coin stack explosion on contact.
    Emits lifecycle signals via SignalModule (Slammed, HitVictim).
    Location: src/server/Hazards/PistonCrusher.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)
local Signal = require(ReplicatedStorage.Packages.SignalModule)

local log = Logger.create("Hazards")

local Services = script.Parent.Parent:WaitForChild("Services")
local CombatServer = require(Services:WaitForChild("CombatServer") :: ModuleScript)

local PistonCrusher = {}
PistonCrusher.__index = PistonCrusher

export type PistonCrusherInstance = {
	instance: Instance,
	part: BasePart,
	startCFrame: CFrame,
	dropDistance: number,
	cycleTime: number,
	anticipationTime: number,
	phaseOffset: number,
	isDestroyed: boolean,
	lastHit: { [Model]: number },
	touchConn: RBXScriptConnection?,

	-- Lifecycle Signals
	Slammed: Signal.Signal<>,
	HitVictim: Signal.Signal<Model, Player?>,

	init: (self: PistonCrusherInstance) -> (),
	destroy: (self: PistonCrusherInstance) -> (),
}

function PistonCrusher.new(instance: Instance): PistonCrusherInstance
	local self = setmetatable({}, PistonCrusher) :: any
	self.instance = instance

	-- Resolve target BasePart (single part or primary part of model)
	local movingPart: BasePart?
	if instance:IsA("BasePart") then
		movingPart = instance
	elseif instance:IsA("Model") then
		movingPart = instance.PrimaryPart
			or instance:FindFirstChild("PistonHead") :: BasePart?
			or instance:FindFirstChild("Head") :: BasePart?
			or instance:FindFirstChildWhichIsA("BasePart")
	end

	if not movingPart then
		error(string.format("[PistonCrusher] Failed to find BasePart on %s", instance.Name))
	end

	self.part = movingPart
	self.startCFrame = movingPart.CFrame

	-- Configuration (Studio Attributes > Config defaults)
	local defaults = Config.HAZARDS and Config.HAZARDS.PISTON_CRUSHER
	local defaultDropDistance = defaults and defaults.DROP_DISTANCE or 12
	local defaultCycleTime = defaults and defaults.CYCLE_TIME or 3.0
	local defaultAnticipation = defaults and defaults.ANTICIPATION_TIME or 0.25

	self.dropDistance = instance:GetAttribute("DropDistance") or defaultDropDistance
	self.cycleTime = instance:GetAttribute("CycleTime") or defaultCycleTime
	self.anticipationTime = instance:GetAttribute("AnticipationTime") or defaultAnticipation
	self.phaseOffset = instance:GetAttribute("PhaseOffset") or 0.0

	self.isDestroyed = false
	self.lastHit = {}

	-- Decoupled Signals
	self.Slammed = Signal.new()
	self.HitVictim = Signal.new()

	self:init()
	return self
end

function PistonCrusher:init()
	self.part.Anchored = true

	-- Touch Collision Listener
	self.touchConn = self.part.Touched:Connect(function(hit)
		if self.isDestroyed then return end

		local character = hit.Parent
		if not character or not character:IsA("Model") then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart") :: Part?
		if not humanoid or not hrp or humanoid.Health <= 0 then return end

		local now = os.clock()
		local lastTime = self.lastHit[character] or 0
		if (now - lastTime) < (self.cycleTime * 0.7) then
			return
		end
		self.lastHit[character] = now

		-- Compute outward squash launch vector from piston center to player
		local pistonPos = self.part.Position
		local victimPos = hrp.Position
		local horizDir = Vector3.new(victimPos.X - pistonPos.X, 0, victimPos.Z - pistonPos.Z)

		local launchDir: Vector3
		if horizDir.Magnitude > 0.5 then
			launchDir = horizDir.Unit
		else
			launchDir = -hrp.CFrame.LookVector
		end

		local knockbackForce = Config.BUMP_BASE_IMPULSE * 1.25
		local launchVector = launchDir * knockbackForce + Vector3.new(0, 35, 0)

		local player = Players:GetPlayerFromCharacter(character)
		log(string.format("[PistonCrusher] Struck %s on %s! Applying squash knockback.", character.Name, self.instance.Name))

		self.HitVictim:Fire(character, player)
		CombatServer.BumpVictimModel(nil, character, launchVector)
	end)

	-- Main Piston Stroke Cycle
	task.spawn(function()
		if self.phaseOffset > 0 then
			task.wait(self.phaseOffset)
		end

		local downPos = self.startCFrame.Position - Vector3.new(0, self.dropDistance, 0)
		local downCFrame = CFrame.new(downPos) * (self.startCFrame - self.startCFrame.Position)

		local slamDuration = 0.20
		local retractDuration = 1.10
		local dwellBottom = 0.35
		local idleTop = math.max(0.5, self.cycleTime - (slamDuration + retractDuration + dwellBottom + self.anticipationTime))

		while not self.isDestroyed and self.part and self.part.Parent do
			-- 1. Idle at Ceiling
			self.part.AssemblyLinearVelocity = Vector3.zero
			task.wait(idleTop)
			if self.isDestroyed then break end

			-- 2. Anticipation / Telegraph (Micro-vibration warning)
			local preTime = os.clock()
			while (os.clock() - preTime) < self.anticipationTime do
				local jitter = Vector3.new(
					(math.random() - 0.5) * 0.2,
					(math.random() - 0.5) * 0.2,
					(math.random() - 0.5) * 0.2
				)
				self.part.CFrame = self.startCFrame + jitter
				task.wait(0.03)
			end
			self.part.CFrame = self.startCFrame
			if self.isDestroyed then break end

			-- 3. Violent Slam Downward with Kinematic Velocity
			local slamVelocity = Vector3.new(0, -self.dropDistance / slamDuration, 0)
			self.part.AssemblyLinearVelocity = slamVelocity

			local slamTween = TweenService:Create(
				self.part,
				TweenInfo.new(slamDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ CFrame = downCFrame }
			)
			slamTween:Play()
			slamTween.Completed:Wait()

			self.Slammed:Fire()

			-- 4. Floor Dwell
			self.part.AssemblyLinearVelocity = Vector3.zero
			task.wait(dwellBottom)
			if self.isDestroyed then break end

			-- 5. Smooth Retract Upward
			local retractVelocity = Vector3.new(0, self.dropDistance / retractDuration, 0)
			self.part.AssemblyLinearVelocity = retractVelocity

			local retractTween = TweenService:Create(
				self.part,
				TweenInfo.new(retractDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = self.startCFrame }
			)
			retractTween:Play()
			retractTween.Completed:Wait()
		end
	end)
end

function PistonCrusher:destroy()
	self.isDestroyed = true

	if self.touchConn then
		self.touchConn:Disconnect()
		self.touchConn = nil
	end

	self.Slammed:DisconnectAll()
	self.HitVictim:DisconnectAll()

	if self.part and self.part.Parent then
		self.part.AssemblyLinearVelocity = Vector3.zero
		self.part.CFrame = self.startCFrame
	end
	table.clear(self.lastHit)
end

return PistonCrusher
