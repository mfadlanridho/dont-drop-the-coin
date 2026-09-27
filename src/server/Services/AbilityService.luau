--!strict
--[[
    AbilityService.luau
    Server orchestrator managing ability registrations, client remote requests, and ability lifecycles.
    Location: src/server/Services/AbilityService.luau (Syncs to ServerScriptService.Server.Services.AbilityService)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal = require(Packages:WaitForChild("SignalModule"))

local AbilitiesFolder = Shared:WaitForChild("Abilities")
local BaseAbility = require(AbilitiesFolder:WaitForChild("BaseAbility"))
local SpeedAbility = require(AbilitiesFolder:WaitForChild("SpeedAbility"))
local JumpAbility = require(AbilitiesFolder:WaitForChild("JumpAbility"))

local AbilityService = {}

-- Signals fired when ability stat multipliers change (Unidirectional pub/sub)
AbilityService.OnSpeedMultiplierChanged = Signal.new() :: Signal.Signal<Player, number>
AbilityService.OnJumpMultiplierChanged = Signal.new() :: Signal.Signal<Player, number>

-- Registered ability class instances
local registeredAbilities: { [string]: any } = {}

--- Registers an ability instance into the service registry
function AbilityService.RegisterAbility(abilityInstance: any)
	if abilityInstance and abilityInstance.Id then
		registeredAbilities[abilityInstance.Id] = abilityInstance
	end
end

-- Register default abilities immediately
AbilityService.RegisterAbility(SpeedAbility.new())
AbilityService.RegisterAbility(JumpAbility.new())

--- Returns a registered ability instance by ID
function AbilityService.GetAbility(abilityId: string): any?
	return registeredAbilities[abilityId]
end

--- Returns all registered abilities
function AbilityService.GetAllAbilities(): { [string]: any }
	return registeredAbilities
end

--- Returns true if a specific ability is active on a player
function AbilityService.IsActive(player: Player, abilityId: string): boolean
	local ability = registeredAbilities[abilityId]
	if ability and typeof(ability.IsActive) == "function" then
		return ability:IsActive(player)
	end
	return false
end

--- Returns active SpeedMultiplier for a player (or 1.0 default)
function AbilityService.GetSpeedMultiplier(player: Player): number
	local speedAbility = registeredAbilities["speed_surge"]
	if speedAbility and speedAbility:IsActive(player) then
		return speedAbility.SpeedMultiplier or 1.6
	end
	return 1.0
end

--- Returns active JumpMultiplier for a player (or 1.0 default)
function AbilityService.GetJumpMultiplier(player: Player): number
	local jumpAbility = registeredAbilities["super_spring"]
	if jumpAbility and jumpAbility:IsActive(player) then
		return jumpAbility.JumpMultiplier or 1.8
	end
	return 1.0
end

--- Triggers an ability activation for a player
function AbilityService.TriggerAbility(player: Player, abilityId: string): boolean
	local ability = registeredAbilities[abilityId]
	if not ability then
		warn(string.format("[AbilityService] Ability with ID '%s' not registered.", tostring(abilityId)))
		return false
	end

	return ability:Activate(player)
end

--- Cancels all active abilities for a player (e.g. on death, knockout, or ragdoll)
function AbilityService.CancelAll(player: Player)
	for _, ability in pairs(registeredAbilities) do
		if typeof(ability.Deactivate) == "function" and ability:IsActive(player) then
			ability:Deactivate(player)
		end
	end
end

function AbilityService.Init()
	-- Register concrete abilities
	AbilityService.RegisterAbility(SpeedAbility.new())
	AbilityService.RegisterAbility(JumpAbility.new())

	local RunService = game:GetService("RunService")
	if RunService:IsRunning() then
		-- Listen for ability activation requests from clients
		local useAbilityRemote = Remotes.Get("UseAbility")
		if useAbilityRemote then
			useAbilityRemote.OnServerEvent:Connect(function(player: Player, abilityId: string?)
				local targetId = abilityId or "speed_surge"
				AbilityService.TriggerAbility(player, targetId)
			end)
		end

		-- Clean up when players leave
		Players.PlayerRemoving:Connect(function(player)
			AbilityService.CancelAll(player)
		end)
	end

	print("[AbilityService] Initialized OOP Ability Service with Speed Surge & Super Spring.")
end

return AbilityService
