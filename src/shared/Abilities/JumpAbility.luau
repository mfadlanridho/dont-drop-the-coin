--!strict
--[[
    JumpAbility.luau
    Concrete ability subclass for Super Spring. Temporarily increases character JumpPower & JumpHeight.
    Location: src/shared/Abilities/JumpAbility.luau (Syncs to ReplicatedStorage.Shared.Abilities.JumpAbility)
--]]

local BaseAbility = require(script.Parent:WaitForChild("BaseAbility"))

export type JumpAbilityType = BaseAbility.BaseAbilityType & {
	JumpMultiplier: number,
}

local JumpAbility = setmetatable({}, { __index = BaseAbility })
JumpAbility.__index = JumpAbility

--- Creates a new Super Spring jump ability instance
function JumpAbility.new(): JumpAbilityType
	local self = BaseAbility.new({
		Id = "super_spring",
		Name = "Super Spring",
		Description = "Boosts player Jump Height by +80% for 4 seconds.",
		Cooldown = 12,
		Duration = 12,
		JumpMultiplier = 1.8,
		SoundId = "rbxassetid://9114223179",
		Icon = "rbxassetid://10709789910",
	})

	return (setmetatable(self, JumpAbility) :: any) :: JumpAbilityType
end

--- Called when Super Spring is activated
function JumpAbility:OnActivate(player: Player)
	local Services = game:GetService("ServerScriptService"):FindFirstChild("Server")
	local AbilityService = Services and Services:FindFirstChild("Services") and Services.Services:FindFirstChild("AbilityService")
	if AbilityService then
		local abilityServiceModule = require(AbilityService :: ModuleScript)
		if abilityServiceModule.OnJumpMultiplierChanged then
			abilityServiceModule.OnJumpMultiplierChanged:Fire(player, self.JumpMultiplier)
		end
	end

	-- Apply jump boost directly to character Humanoid
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.JumpHeight = (humanoid.JumpHeight > 0 and humanoid.JumpHeight or 7.2) * self.JumpMultiplier
		humanoid.JumpPower = (humanoid.JumpPower > 0 and humanoid.JumpPower or 50) * self.JumpMultiplier
	end
end

--- Called when Super Spring expires or is cancelled
function JumpAbility:OnDeactivate(player: Player)
	local Services = game:GetService("ServerScriptService"):FindFirstChild("Server")
	local AbilityService = Services and Services:FindFirstChild("Services") and Services.Services:FindFirstChild("AbilityService")
	if AbilityService then
		local abilityServiceModule = require(AbilityService :: ModuleScript)
		if abilityServiceModule.OnJumpMultiplierChanged then
			abilityServiceModule.OnJumpMultiplierChanged:Fire(player, 1.0)
		end
	end

	-- Restore normal upgraded jump stats via UpgradeService
	local UpgradeServiceObj = Services and Services:FindFirstChild("Services") and Services.Services:FindFirstChild("UpgradeService")
	if UpgradeServiceObj then
		local UpgradeService = require(UpgradeServiceObj :: ModuleScript)
		if typeof(UpgradeService.ApplyStats) == "function" then
			UpgradeService.ApplyStats(player)
		end
	else
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.JumpHeight = 7.2
			humanoid.JumpPower = 50
		end
	end
end

return JumpAbility
