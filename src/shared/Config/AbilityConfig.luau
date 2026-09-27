--!strict
--[[
    AbilityConfig.luau
    Simple data-driven configuration for player abilities and stat multipliers.
    Location: src/shared/Config/AbilityConfig.luau (Syncs to ReplicatedStorage.Shared.Config.AbilityConfig)
--]]

export type AbilityData = {
	Id: string,
	Name: string,
	Cooldown: number,
	Duration: number,
	SpeedMultiplier: number?,
	JumpMultiplier: number?,
	SoundId: string?,
}

local AbilityConfig: { [string]: AbilityData } = {
	["speed_surge"] = {
		Id = "speed_surge",
		Name = "Speed Surge",
		Cooldown = 15,
		Duration = 5,
		SpeedMultiplier = 1.6, -- +60% WalkSpeed
		SoundId = "rbxassetid://9114223179",
	},
}

AbilityConfig.DEFAULT = "speed_surge"

return AbilityConfig
