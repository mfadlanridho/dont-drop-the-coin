--!strict
--[[
    BaseAbility.luau
    Abstract parent class for player abilities. Handles cooldown tracking, player state validation,
    duration lifecycle scheduling, and remote event replication.
    Location: src/shared/Abilities/BaseAbility.luau (Syncs to ReplicatedStorage.Shared.Abilities.BaseAbility)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))

export type AbilityProperties = {
	Id: string,
	Name: string,
	Description: string,
	Cooldown: number,
	Duration: number,
	Icon: string?,
	SoundId: string?,
	SpeedMultiplier: number?,
	JumpMultiplier: number?,
}

export type BaseAbilityType = {
	Id: string,
	Name: string,
	Description: string,
	Cooldown: number,
	Duration: number,
	Icon: string?,
	SoundId: string?,
	SpeedMultiplier: number?,
	JumpMultiplier: number?,
	Cooldowns: { [Player]: number },
	ActiveThreads: { [Player]: thread },
	new: (props: AbilityProperties) -> BaseAbilityType,
	CanActivate: (self: BaseAbilityType, player: Player) -> (boolean, string?),
	Activate: (self: BaseAbilityType, player: Player) -> boolean,
	Deactivate: (self: BaseAbilityType, player: Player) -> (),
	GetCooldownRemaining: (self: BaseAbilityType, player: Player) -> number,
	IsActive: (self: BaseAbilityType, player: Player) -> boolean,
	OnActivate: (self: BaseAbilityType, player: Player) -> (),
	OnDeactivate: (self: BaseAbilityType, player: Player) -> (),
}

local BaseAbility = {}
BaseAbility.__index = BaseAbility

function BaseAbility.new(props: AbilityProperties): BaseAbilityType
	local self = setmetatable({
		Id = props.Id,
		Name = props.Name,
		Description = props.Description or "",
		Cooldown = props.Cooldown or 10,
		Duration = props.Duration or 0,
		Icon = props.Icon,
		SoundId = props.SoundId,
		SpeedMultiplier = props.SpeedMultiplier,
		JumpMultiplier = props.JumpMultiplier,
		Cooldowns = {},
		ActiveThreads = {},
	}, BaseAbility)

	return (self :: any) :: BaseAbilityType
end

--- Returns remaining cooldown time in seconds for a player (0 if ready)
function BaseAbility:GetCooldownRemaining(player: Player): number
	local lastUsed = self.Cooldowns[player] or 0
	local elapsed = os.clock() - lastUsed
	return math.max(0, self.Cooldown - elapsed)
end

--- Returns true if ability duration is currently running on player
function BaseAbility:IsActive(player: Player): boolean
	return self.ActiveThreads[player] ~= nil
end

--- Validates whether the player can activate this ability
function BaseAbility:CanActivate(player: Player): (boolean, string?)
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "PlayerDeadOrMissing"
	end

	if PlayerFSM.GetState(player) ~= "Normal" then
		return false, "InvalidPlayerState"
	end

	local remainingCd = self:GetCooldownRemaining(player)
	if remainingCd > 0 then
		return false, "OnCooldown"
	end

	return true, nil
end

--- Triggers ability activation, records cooldown, fires remotes, and schedules deactivation
function BaseAbility:Activate(player: Player): boolean
	local canAct, reason = self:CanActivate(player)
	if not canAct then
		return false
	end

	-- 1. Apply Cooldown timestamp
	self.Cooldowns[player] = os.clock()

	-- 2. Cancel previous active thread if re-triggered
	if self.ActiveThreads[player] then
		task.cancel(self.ActiveThreads[player])
		self.ActiveThreads[player] = nil
	end

	-- 3. Schedule duration expiration cleanup
	if self.Duration > 0 then
		self.ActiveThreads[player] = task.delay(self.Duration, function()
			self.ActiveThreads[player] = nil
			self:Deactivate(player)
		end)
	end

	-- 4. Run concrete child activation logic
	self:OnActivate(player)

	-- 5. Replicate UI Cooldown & Audio feedback
	local updateRemote = Remotes.Get("UpdateAbilityState")
	if updateRemote then
		updateRemote:FireClient(player, self.Id, self.Cooldown, self.Duration)
	end

	if self.SoundId then
		local soundRemote = Remotes.Get("PlaySound")
		local char = player.Character
		if soundRemote and char then
			soundRemote:FireClient(player, self.SoundId, char:FindFirstChild("HumanoidRootPart"))
		end
	end

	return true
end

--- Deactivates the ability and triggers concrete child cleanup
function BaseAbility:Deactivate(player: Player)
	if self.ActiveThreads[player] then
		task.cancel(self.ActiveThreads[player])
		self.ActiveThreads[player] = nil
	end
	self:OnDeactivate(player)
end

--- Virtual method to be overridden by child classes
function BaseAbility:OnActivate(player: Player)
	-- Concrete implementation in child classes
end

--- Virtual method to be overridden by child classes
function BaseAbility:OnDeactivate(player: Player)
	-- Concrete implementation in child classes
end

-- Clean up player data on disconnect
Players.PlayerRemoving:Connect(function(player)
	-- Handled per-instance or globally
end)

return BaseAbility
