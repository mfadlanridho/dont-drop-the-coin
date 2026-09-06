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
	DataVersion = 2,
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
Config.INITIAL_STACK_COUNT = 3 -- Initial coin stack count given on spawn (for testing/gameplay)
Config.MAX_RENDER_STACK = 30 -- Maximum physical coin models welded to head
Config.STACK_FOLLOW_HEAD_ROTATION = false -- If true, stack tilts with head animations. If false, stays upright aligned with body.
Config.COIN_NODE_RESPAWN_TIME = 3 -- Seconds before coin node respawns
Config.DESPAWN_DROPPED_COIN_TIME = 10 -- Lifetime of dropped explosion coins

-- Coin Spawner & Node System (CollectionService & Upward Face Math)
Config.COIN_SPAWNER = {
	TAG = "CoinSpawnSurface",
	ALIASES = { "CoinSpawner" }, -- Backward-compatible aliases
	NODE_TAG = "CoinNode",
	DEFAULT_HOVER_HEIGHT = 2.0, -- Studs above the detected upward surface
	SAFETY_MARGIN = 2.5,        -- Inset margin in studs from face edges to avoid spawning off ledges
	COIN_SPACING = 8.0,         -- Distance between coins in studs when auto-filling the face area
	MAX_COINS_PER_SURFACE = 10, -- Maximum coins allowed on a single surface to protect performance
	TIER_COLORS = {
		[1] = Color3.fromRGB(255, 215, 0),   -- Zone 1: Gold Neon
		[2] = Color3.fromRGB(0, 230, 255),   -- Zone 2: Cyan Neon
		[3] = Color3.fromRGB(180, 50, 255),  -- Zone 3: Purple Neon
	},
	ANIMATION = {
		ROTATION_SPEED = 2.5, -- Radians per second
		BOB_AMPLITUDE = 0.35, -- Studs up/down
		BOB_FREQUENCY = 3.0,  -- Oscillation cycles per second
	},
}

-- Combat & Physics
Config.BUMP_COOLDOWN = 5 -- Cooldown in seconds for Dash Bump
Config.DASH_DISTANCE = 15 -- Exact forward dash distance in studs
Config.DASH_DURATION = 1 -- Duration of forward dash in seconds
Config.DASH_ANIMATION_ID = "rbxassetid://102382549309160" -- Roblox Asset ID for Dash skill animation
Config.BUMP_BASE_IMPULSE = 50 -- Base knockback force applied to victim
Config.BUMP_STACK_IMPULSE_MULTIPLIER = 2 -- Extra knockback force per stack height
Config.RAGDOLL_DURATION = 2.5 -- Duration of physics ragdoll in seconds

-- Monetization & Community
Config.GROUP_ID = 0 -- Replace with your actual Roblox Group ID
Config.GROUP_CASH_MULTIPLIER = 1.20 -- +20% permanent cash boost for group members

-- Environmental Hazards Configuration
Config.HAZARDS = {
	DISAPPEARING_PLATFORM = {
		WARNING_DELAY = 0.85, -- Seconds platform flashes before dropping collision
		RESPAWN_DELAY = 2.5,  -- Seconds platform stays invisible before regenerating
		WARNING_COLOR = Color3.fromRGB(255, 60, 60), -- Flash alert color
	},
	PISTON_CRUSHER = {
		DROP_DISTANCE = 12,     -- Travel distance in studs
		CYCLE_TIME = 3.0,       -- Full cycle time in seconds
		ANTICIPATION_TIME = 0.25, -- Warning micro-jitter duration
	},
	PENDULUM = {
		SWING_ANGLE = 50,  -- Maximum swing angle in degrees
		SWING_SPEED = 2.5, -- Oscillation speed multiplier
		ARM_LENGTH = 10,   -- Stud distance from blade to pivot
	},
}

return Config
