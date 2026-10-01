--!strict
--[[
    RebirthConfig.luau
    Game-specific Rebirth configuration for Don't Drop The Coin!
    Location: src/shared/Config/RebirthConfig.luau (Syncs to ReplicatedStorage.Shared.Config.RebirthConfig)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local RebirthModule = require(Packages:WaitForChild("RebirthModule") :: ModuleScript)

local RebirthConfig: RebirthModule.RebirthConfig = {
	MaxRebirth = 50,

	--- Formula determining required banked Coins for the next Rebirth level
	GetRequirements = function(currentRebirth: number, playerData: any): (RebirthModule.RequirementEntry, { RebirthModule.ExtraCondition }?)
		local currentCoins = (playerData and playerData.Coins) or 0
		-- Exponential curve: 1,000 * (2.2 ^ Rebirth) -> 1K, 2.2K, 4.84K, 10.6K, 23.4K...
		local targetCoins = RebirthModule.Formula.Exponential(1000, 2.2, currentRebirth)

		local primaryReq: RebirthModule.RequirementEntry = {
			Type = "Currency",
			Key = "Coins",
			Current = currentCoins,
			Target = targetCoins,
			IsMet = currentCoins >= targetCoins,
			Ratio = math.clamp(currentCoins / math.max(1, targetCoins), 0, 1),
			Description = string.format("%s / %s Coins", RebirthModule.Formula.FormatCompact(currentCoins), RebirthModule.Formula.FormatCompact(targetCoins)),
		}

		return primaryReq, nil
	end,

	--- Multiplier applied to Bank Vault cashouts (+25% per Rebirth)
	GetMultiplier = function(currentRebirth: number): number
		return 1.0 + (math.max(0, currentRebirth) * 0.25)
	end,

	--- Schema of state values reset upon executing a Rebirth
	ResetCallback = function(playerData: any)
		playerData.Coins = 0
		playerData.Upgrades = {
			SpeedLevel = 1,
			StrengthLevel = 1,
			JumpLevel = 1,
		}
	end,

	--- Executed on Rebirth success to update player data
	RewardCallback = function(player: Player, newRebirth: number, playerData: any)
		playerData.Rebirths = newRebirth
	end,
}

return RebirthConfig
