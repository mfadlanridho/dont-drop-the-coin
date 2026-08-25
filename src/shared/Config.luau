--!strict
--[[
    Config.luau
    Central configuration file for Don't Drop The Coin!
    Location: src/shared/Config.luau (Syncs to ReplicatedStorage.Shared.Config)
--]]

local Config = {}

-- DataStore Settings
Config.DATASTORE_KEY = "DontDropTheCoin_v1"
Config.AUTO_SAVE_INTERVAL = 300 -- Save session data every 5 minutes

-- Default Player Data Schema
Config.DEFAULT_DATA = {
	Coins = 0,
	TotalBanked = 0,
	EquippedSkin = "Default",
	OwnedPasses = {},
	LastSaved = 0,
}

-- Zone Multipliers (Cashout Multipliers)
Config.ZONE_MULTIPLIERS = {
	Ground = 0, -- Safe Zone Lobby (0x)
	Zone1 = 1,  -- Sunny Start (1x)
	Zone2 = 2,  -- Chaos Factory (2x)
	Zone3 = 3,  -- Void Lunatic (3x)
}

-- Coin & Stacking Mechanics
Config.MAX_RENDER_STACK = 30 -- Maximum physical coin models welded to head
Config.STACK_FOLLOW_HEAD_ROTATION = false -- If true, stack tilts with head animations. If false, stays upright aligned with body.
Config.COIN_NODE_RESPAWN_TIME = 3 -- Seconds before coin node respawns
Config.DESPAWN_DROPPED_COIN_TIME = 10 -- Lifetime of dropped explosion coins

-- Combat & Physics
Config.BUMP_COOLDOWN = 5 -- Cooldown in seconds for Dash Bump
Config.DASH_DISTANCE = 15 -- Exact forward dash distance in studs
Config.DASH_DURATION = 0.3 -- Duration of forward dash in seconds
Config.BUMP_BASE_IMPULSE = 50 -- Base knockback force applied to victim
Config.BUMP_STACK_IMPULSE_MULTIPLIER = 2 -- Extra knockback force per stack height
Config.RAGDOLL_DURATION = 2.5 -- Duration of physics ragdoll in seconds

-- Monetization & Community
Config.GROUP_ID = 0 -- Replace with your actual Roblox Group ID
Config.GROUP_CASH_MULTIPLIER = 1.20 -- +20% permanent cash boost for group members

-- Sound Matrix Pitch Shift
Config.BASE_PITCH = 1.0
Config.PITCH_INCREMENT = 0.05
Config.MAX_PITCH = 2.0
Config.PITCH_RESET_TIME = 3 -- Reset combo pitch after 3 seconds of no pickups

return Config
