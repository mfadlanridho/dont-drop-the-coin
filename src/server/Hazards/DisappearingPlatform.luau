--!nonstrict
--[[
    DisappearingPlatform.luau
    Modular OOP component for Zone 3 Disappearing Platforms.
    Server-authoritative state manager that drives deterministic client-side collision and visuals
    via the "PlatformState" attribute ("Stable" -> "Warning" -> "Vanished" -> "Stable").
    Emits decoupled lifecycle signals via SignalModule (Triggered, Vanished, Regenerated).
    Location: src/server/Hazards/DisappearingPlatform.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)
local Signal = require(ReplicatedStorage.Packages.SignalModule)

local log = Logger.create("Hazards")

local DisappearingPlatform = {}
DisappearingPlatform.__index = DisappearingPlatform

export type DisappearingPlatformInstance = {
	instance: Instance,
	targetParts: { BasePart },
	warningDelay: number,
	respawnDelay: number,
	warningColor: Color3,
	isTriggered: boolean,
	isDestroyed: boolean,
	touchConnections: { RBXScriptConnection },

	-- Lifecycle Signals
	Triggered: Signal.Signal<Model, Player?>,
	Vanished: Signal.Signal<>,
	Regenerated: Signal.Signal<>,

	init: (self: DisappearingPlatformInstance) -> (),
	trigger: (self: DisappearingPlatformInstance, character: Model, player: Player?) -> (),
	destroy: (self: DisappearingPlatformInstance) -> (),
}

function DisappearingPlatform.new(instance: Instance): DisappearingPlatformInstance
	local self = setmetatable({}, DisappearingPlatform) :: any
	self.instance = instance

	-- Resolve target parts (single BasePart or all BaseParts inside a Model)
	self.targetParts = {}
	if instance:IsA("BasePart") then
		table.insert(self.targetParts, instance)
	elseif instance:IsA("Model") then
		for _, desc in ipairs(instance:GetDescendants()) do
			if desc:IsA("BasePart") then
				table.insert(self.targetParts, desc)
			end
		end
	end

	if #self.targetParts == 0 then
		error(string.format("[DisappearingPlatform] No BaseParts found on %s", instance.Name))
	end

	-- Configuration (Studio Attribute overrides > Config defaults)
	local defaults = Config.HAZARDS and Config.HAZARDS.DISAPPEARING_PLATFORM
	local defaultWarningDelay = defaults and defaults.WARNING_DELAY or 0.85
	local defaultRespawnDelay = defaults and defaults.RESPAWN_DELAY or 2.5
	local defaultWarningColor = defaults and defaults.WARNING_COLOR or Color3.fromRGB(255, 60, 60)

	self.warningDelay = instance:GetAttribute("WarningDelay") or defaultWarningDelay
	self.respawnDelay = instance:GetAttribute("RespawnDelay") or defaultRespawnDelay
	self.warningColor = instance:GetAttribute("WarningColor") or defaultWarningColor

	-- Replicate configuration to attributes for client controllers
	instance:SetAttribute("WarningDelay", self.warningDelay)
	instance:SetAttribute("RespawnDelay", self.respawnDelay)
	instance:SetAttribute("WarningColor", self.warningColor)
	instance:SetAttribute("PlatformState", "Stable")

	self.isTriggered = false
	self.isDestroyed = false
	self.touchConnections = {}

	-- Initialize Decoupled Signals
	self.Triggered = Signal.new()
	self.Vanished = Signal.new()
	self.Regenerated = Signal.new()

	self:init()
	return self
end

function DisappearingPlatform:init()
	for _, part in ipairs(self.targetParts) do
		part.Anchored = true
		local conn = part.Touched:Connect(function(hit)
			if self.isTriggered or self.isDestroyed then return end

			local character = hit.Parent
			if not character or not character:IsA("Model") then return end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then return end

			local player = Players:GetPlayerFromCharacter(character)
			self:trigger(character, player)
		end)
		table.insert(self.touchConnections, conn)
	end
end

function DisappearingPlatform:trigger(character: Model, player: Player?)
	if self.isTriggered or self.isDestroyed then return end
	self.isTriggered = true

	log(string.format("[DisappearingPlatform] %s stepped on %s! Starting %.2fs warning.", character.Name, self.instance.Name, self.warningDelay))

	-- 1. Warning State
	self.instance:SetAttribute("PlatformState", "Warning")
	self.Triggered:Fire(character, player)

	task.wait(self.warningDelay)
	if self.isDestroyed then return end

	-- 2. Vanished State
	self.instance:SetAttribute("PlatformState", "Vanished")
	log(string.format("[DisappearingPlatform] %s vanished!", self.instance.Name))
	self.Vanished:Fire()

	task.wait(self.respawnDelay)
	if self.isDestroyed then return end

	-- 3. Regenerated / Stable State
	self.instance:SetAttribute("PlatformState", "Stable")
	log(string.format("[DisappearingPlatform] %s regenerated successfully.", self.instance.Name))
	self.Regenerated:Fire()

	-- 4. Debounce Cooldown: 0.5s grace period before the platform can be re-triggered
	task.wait(0.5)
	self.isTriggered = false
end

function DisappearingPlatform:destroy()
	self.isDestroyed = true

	for _, conn in ipairs(self.touchConnections) do
		conn:Disconnect()
	end
	table.clear(self.touchConnections)

	-- Disconnect and cleanup Signals
	self.Triggered:DisconnectAll()
	self.Vanished:DisconnectAll()
	self.Regenerated:DisconnectAll()

	-- Reset attribute state
	if self.instance and self.instance.Parent then
		self.instance:SetAttribute("PlatformState", "Stable")
	end
	table.clear(self.targetParts)
end

return DisappearingPlatform
