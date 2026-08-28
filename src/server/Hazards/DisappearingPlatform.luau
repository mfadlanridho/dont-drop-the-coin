--!strict
--[[
    DisappearingPlatform.luau
    Modular OOP component for Zone 3 Disappearing Platforms.
    Flashes warning color on player contact, disables CanCollide & Transparency after 1.0s, and regenerates after 2.0s.
    Location: src/server/Hazards/DisappearingPlatform.luau
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)

local log = Logger.create("Combat")

local DisappearingPlatform = {}
DisappearingPlatform.__index = DisappearingPlatform

type PlatformInstance = {
	part: BasePart,
	originalColor: Color3,
	originalTransparency: number,
	warningDelay: number,
	respawnDelay: number,
	isTriggered: boolean,
	touchConn: RBXScriptConnection?,
}

function DisappearingPlatform.new(part: BasePart, warningDelay: number?, respawnDelay: number?): PlatformInstance
	local self = setmetatable({}, DisappearingPlatform) :: any
	self.part = part
	self.originalColor = part.Color
	self.originalTransparency = part.Transparency
	self.warningDelay = warningDelay or 1.0
	self.respawnDelay = respawnDelay or 2.0
	self.isTriggered = false

	self:init()
	return self
end

function DisappearingPlatform:init()
	self.part.Anchored = true

	self.touchConn = self.part.Touched:Connect(function(hit)
		if self.isTriggered then return end

		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		self:triggerDisappear(player)
	end)
end

function DisappearingPlatform:triggerDisappear(player: Player)
	self.isTriggered = true
	log(string.format("[DisappearingPlatform] Player %s triggered platform %s!", player.Name, self.part.Name))

	-- Warning Flash Tween (Color -> Warning Red)
	local warningTween = TweenService:Create(
		self.part,
		TweenInfo.new(self.warningDelay, Enum.EasingStyle.Linear),
		{ Color = Color3.fromRGB(255, 50, 50), Transparency = 0.4 }
	)
	warningTween:Play()

	task.wait(self.warningDelay)

	-- Disappear & Disable Collision
	self.part.CanCollide = false
	self.part.Transparency = 1

	task.wait(self.respawnDelay)

	-- Regenerate Platform
	self.part.Color = self.originalColor
	self.part.Transparency = self.originalTransparency
	self.part.CanCollide = true
	self.isTriggered = false
	log(string.format("[DisappearingPlatform] Platform %s regenerated.", self.part.Name))
end

function DisappearingPlatform:destroy()
	if self.touchConn then
		self.touchConn:Disconnect()
		self.touchConn = nil
	end
end

return DisappearingPlatform
