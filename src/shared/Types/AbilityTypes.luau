--!strict
--[[
    AbilityTypes.luau
    Exported Luau types for Abilities, Buffs/Modifiers, and Player Loadout State.
    Location: src/shared/Types/AbilityTypes.luau (Syncs to ReplicatedStorage.Shared.Types.AbilityTypes)
--]]

export type AbilityCategory = 
	| "SelfBuff"     -- Stat multipliers (Speed, Jump, Strength/Weight)
	| "Aura"         -- Persistent area effect centered on player (Coin Magnet)
	| "AoE"          -- Instant radial blast (Freeze Guard, Shockwave)
	| "Consumable"   -- Single-use inventory item / pickup

export type AbilityModifiers = {
	-- 1. Stat Multipliers
	speedMultiplier: number?,           -- e.g., 1.6 = +60% WalkSpeed
	jumpMultiplier: number?,            -- e.g., 1.75 = +75% JumpPower
	weightDiscountMultiplier: number?,  -- e.g., 0.8 = 80% discount on stack weight penalty

	-- 2. Coin Magnet Parameters
	magnetRadius: number?,              -- e.g., 25 studs
	magnetSpeed: number?,               -- e.g., 40 studs/sec pull speed
	targetDroppedCoins: boolean?,       -- Pull scatter explosion coins?
	targetFloatingCoins: boolean?,      -- Pull standard platform coins?

	-- 3. Guard & Hazard Control
	freezeRadius: number?,              -- e.g., 20 studs AoE
	freezeDuration: number?,            -- e.g., 4.0 seconds
	affectGuards: boolean?,             -- Freeze Balerina / Drone guards?
	affectPlayers: boolean?,            -- Freeze/slow opposing players?

	-- 4. Protection & Stack Rules
	immuneToKnockback: boolean?,        -- "Super Glue" effect
	preventCoinDrop: boolean?,          -- Prevents loot explosion if bumped
}

export type AbilityDefinition = {
	id: string,                         -- Unique ID, e.g. "speed_surge", "coin_magnet"
	name: string,                       -- Display name: "Speed Surge"
	description: string,
	category: AbilityCategory,
	icon: string,                       -- Asset ID or emoji
	
	-- Timing & Economics
	cooldown: number,                   -- Cooldown in seconds
	duration: number,                   -- Active duration in seconds (0 for instant trigger)
	isConsumable: boolean,              -- Is it a limited-count item?
	cost: number?,                      -- Banked Coins cost (if purchasable in shop)

	-- Mechanics & Modifiers
	modifiers: AbilityModifiers,

	-- Visuals & Audio
	vfxName: string?,                   -- Name of particle template or visual effect
	animationId: string?,               -- Character animation asset ID
	soundActivation: string?,           -- Activation audio asset ID
	soundLoop: string?,                 -- Looping audio asset ID during active duration
}

export type ActiveEffectInstance = {
	effectId: string,
	abilityId: string,
	player: Player,
	startTime: number,
	duration: number,
	modifiers: AbilityModifiers,
	vfxInstance: Instance?,
	soundInstance: Sound?,
	cleanupTask: thread?,
}

export type PlayerAbilityData = {
	EquippedSkill: string,
	UnlockedAbilities: { [string]: boolean },
	Consumables: { [string]: number },
}

return {}
