--!strict
--[[
    SpeedAbility.luau
    Concrete ability subclass for Speed Surge. Temporarily increases character WalkSpeed multiplier.
    Location: src/shared/Abilities/SpeedAbility.luau (Syncs to ReplicatedStorage.Shared.Abilities.SpeedAbility)
--]]

local BaseAbility = require(script.Parent:WaitForChild("BaseAbility"))

export type SpeedAbilityType = BaseAbility.BaseAbilityType & {
	SpeedMultiplier: number,
}

local SpeedAbility = setmetatable({}, { __index = BaseAbility })
SpeedAbility.__index = SpeedAbility

--- Creates a new Speed Surge ability instance
function SpeedAbility.new(): SpeedAbilityType
	local self = BaseAbility.new({
		Id = "speed_surge",
		Name = "Speed Surge",
		Description = "Boosts player WalkSpeed by +60% for 5 seconds.",
		Cooldown = 15,
		Duration = 5,
		SpeedMultiplier = 1.6,
		SoundId = "rbxassetid://9114223179",
		Icon = "rbxassetid://10709789910",
	})

	return (setmetatable(self, SpeedAbility) :: any) :: SpeedAbilityType
end

--- Called when Speed Surge is activated
function SpeedAbility:OnActivate(player: Player)
	local Services = game:GetService("ServerScriptService"):FindFirstChild("Server")
	local AbilityServiceObj = Services and Services:FindFirstChild("Services") and Services.Services:FindFirstChild("AbilityService")
	if AbilityServiceObj then
		local AbilityService = require(AbilityServiceObj :: ModuleScript)
		if AbilityService.OnSpeedMultiplierChanged then
			AbilityService.OnSpeedMultiplierChanged:Fire(player, self.SpeedMultiplier)
		end
	end

	local StackServerObj = Services and Services:FindFirstChild("Services") and Services.Services:FindFirstChild("StackServer")
	if StackServerObj then
		local StackServer = require(StackServerObj :: ModuleScript)
		if typeof(StackServer.RecalculateEncumbrance) == "function" then
			StackServer.RecalculateEncumbrance(player)
		end
	end
end

--- Called when Speed Surge expires or is cancelled
function SpeedAbility:OnDeactivate(player: Player)
	local Services = game:GetService("ServerScriptService"):FindFirstChild("Server")
	local AbilityServiceObj = Services and Services:FindFirstChild("Services") and Services.Services:FindFirstChild("AbilityService")
	if AbilityServiceObj then
		local AbilityService = require(AbilityServiceObj :: ModuleScript)
		if AbilityService.OnSpeedMultiplierChanged then
			AbilityService.OnSpeedMultiplierChanged:Fire(player, 1.0)
		end
	end

	local StackServerObj = Services and Services:FindFirstChild("Services") and Services.Services:FindFirstChild("StackServer")
	if StackServerObj then
		local StackServer = require(StackServerObj :: ModuleScript)
		if typeof(StackServer.RecalculateEncumbrance) == "function" then
			StackServer.RecalculateEncumbrance(player)
		end
	end
end

return SpeedAbility
