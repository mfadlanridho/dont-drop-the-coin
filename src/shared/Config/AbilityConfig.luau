--!strict
--[[
    AbilityConfig.luau
    Central configuration and registry for player abilities, buffs, and consumable items.
    Location: src/shared/Config/AbilityConfig.luau (Syncs to ReplicatedStorage.Shared.Config.AbilityConfig)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = script.Parent.Parent
local Types = require(Shared:WaitForChild("Types"):WaitForChild("AbilityTypes"))

export type AbilityDefinition = Types.AbilityDefinition
export type AbilityModifiers = Types.AbilityModifiers

local AbilityConfig: { [string]: Types.AbilityDefinition } = {
	-- 🏃 STAT BOOST: SPEED SURGE
	["speed_surge"] = {
		id = "speed_surge",
		name = "Speed Surge",
		description = "Gain +60% WalkSpeed and a swift neon trail for 5 seconds.",
		category = "SelfBuff",
		icon = "⚡",
		cooldown = 15,
		duration = 5,
		isConsumable = false,
		cost = 100,
		modifiers = {
			speedMultiplier = 1.6,
		},
		vfxName = "SpeedTrailVFX",
		soundActivation = "rbxassetid://9114223179",
	},

	-- 🦘 STAT BOOST: SPRING SHOES (JUMP & WEIGHT DISCOUNT)
	["spring_shoes"] = {
		id = "spring_shoes",
		name = "Spring Shoes",
		description = "Boost jump power by +75% and reduce coin stack weight by 80% for 6 seconds.",
		category = "SelfBuff",
		icon = "🦘",
		cooldown = 18,
		duration = 6,
		isConsumable = false,
		cost = 150,
		modifiers = {
			jumpMultiplier = 1.75,
			weightDiscountMultiplier = 0.80,
		},
		vfxName = "JumpSpringVFX",
		soundActivation = "rbxassetid://9114223179",
	},

	-- 🧲 UTILITY: COIN MAGNET
	["coin_magnet"] = {
		id = "coin_magnet",
		name = "Coin Vacuum",
		description = "Pulls all floating and dropped coins within 25 studs directly to your stack for 6 seconds.",
		category = "Aura",
		icon = "🧲",
		cooldown = 20,
		duration = 6,
		isConsumable = false,
		cost = 250,
		modifiers = {
			magnetRadius = 25,
			magnetSpeed = 40,
			targetDroppedCoins = true,
			targetFloatingCoins = true,
		},
		vfxName = "MagnetRingsVFX",
		soundActivation = "rbxassetid://9114223179",
		soundLoop = "rbxassetid://9114223179",
	},

	-- ❄️ COMBAT / GRIEFING: FROST BOMB (GUARD FREEZE)
	["guard_freeze"] = {
		id = "guard_freeze",
		name = "Frost Bomb",
		description = "Freezes all nearby AI guards and obstacles in a 20-stud radius for 4 seconds.",
		category = "AoE",
		icon = "❄️",
		cooldown = 25,
		duration = 0, -- Instant activation (duration applies to targets via freezeDuration)
		isConsumable = false,
		cost = 300,
		modifiers = {
			freezeRadius = 20,
			freezeDuration = 4.0,
			affectGuards = true,
			affectPlayers = false,
		},
		vfxName = "IceExplosionVFX",
		soundActivation = "rbxassetid://9113525391",
	},

	-- 🍯 DEFENSE: SUPER GLUE
	["super_glue"] = {
		id = "super_glue",
		name = "Super Glue",
		description = "Locks your coin stack in place for 6 seconds. Immune to knockback drops and player bumps!",
		category = "SelfBuff",
		icon = "🍯",
		cooldown = 30,
		duration = 6,
		isConsumable = false,
		cost = 400,
		modifiers = {
			immuneToKnockback = true,
			preventCoinDrop = true,
			weightDiscountMultiplier = 1.0,
		},
		vfxName = "GoldenGlowVFX",
		soundActivation = "rbxassetid://9120729973",
	},
}

-- Default starter ability equipped for new players
AbilityConfig.DEFAULT_EQUIPPED = "speed_surge"

function AbilityConfig.Get(abilityId: string): Types.AbilityDefinition?
	return AbilityConfig[abilityId]
end

return AbilityConfig
