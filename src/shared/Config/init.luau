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

-- Zone Tier Data & Progression (Tiers 1 to 10)
Config.ZONE_TIERS = {
	[1] = {
		Name = "Bronze",
		Multiplier = 1.00,
		Weight = 1.0,
		Color = Color3.fromRGB(255, 215, 0), -- Gold/Bronze Neon
		ModelName = "Coin_Tier1",
	},
	[2] = {
		Name = "Silver",
		Multiplier = 1.25,
		Weight = 1.2,
		Color = Color3.fromRGB(0, 230, 255), -- Cyan Neon
		ModelName = "Coin_Tier2",
	},
	[3] = {
		Name = "Gold",
		Multiplier = 1.50,
		Weight = 1.5,
		Color = Color3.fromRGB(255, 180, 0), -- Deep Gold Neon
		ModelName = "Coin_Tier3",
	},
	[4] = {
		Name = "Emerald",
		Multiplier = 1.75,
		Weight = 1.8,
		Color = Color3.fromRGB(50, 230, 90), -- Emerald Green Neon
		ModelName = "Coin_Tier4",
	},
	[5] = {
		Name = "Sapphire",
		Multiplier = 2.00,
		Weight = 2.2,
		Color = Color3.fromRGB(30, 140, 255), -- Sapphire Blue Neon
		ModelName = "Coin_Tier5",
	},
	[6] = {
		Name = "Ruby",
		Multiplier = 2.25,
		Weight = 2.6,
		Color = Color3.fromRGB(255, 45, 70), -- Ruby Red Neon
		ModelName = "Coin_Tier6",
	},
	[7] = {
		Name = "Amethyst",
		Multiplier = 2.50,
		Weight = 3.0,
		Color = Color3.fromRGB(180, 50, 255), -- Purple Neon
		ModelName = "Coin_Tier7",
	},
	[8] = {
		Name = "Diamond",
		Multiplier = 2.75,
		Weight = 3.5,
		Color = Color3.fromRGB(140, 240, 255), -- Diamond Bright Cyan
		ModelName = "Coin_Tier8",
	},
	[9] = {
		Name = "Void",
		Multiplier = 3.00,
		Weight = 4.0,
		Color = Color3.fromRGB(90, 20, 160), -- Deep Void Violet
		ModelName = "Coin_Tier9",
	},
	[10] = {
		Name = "Celestial",
		Multiplier = 3.25,
		Weight = 5.0,
		Color = Color3.fromRGB(255, 255, 255), -- Radiant Celestial White
		ModelName = "Coin_Tier10",
	},
}

-- Player Movement & Coin Encumbrance
Config.ENCUMBRANCE = {
	BASE_WALKSPEED = 16, -- Standard Roblox WalkSpeed (studs/sec)
	MIN_WALKSPEED = 8,   -- Minimum WalkSpeed cap (prevents impossible jumps)
	WEIGHT_PENALTY_FACTOR = 0.02, -- Speed penalty per unit of total stack weight (25 total weight = 50% reduction)
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
	MAX_COINS_PER_SURFACE = 16, -- Maximum coins allowed on a single surface to protect performance
	AUTO_DISCOVER_ZONE_FLOORS = true, -- Automatically scan workspace for Zone1..10 and spawn floor coins
	ZONE_FLOOR_COIN_SPACING = 18.0, -- Distance between coins on large zone floor slabs
	ZONE_FLOOR_SAFETY_MARGIN = 6.0, -- Inset margin from edge of zone floor slabs
	ZONE_FLOOR_HOVER_HEIGHT = 2.0, -- Studs above the floor slab
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

-- Guard Model Rig Templates & Associated Animations (Rig-specific definitions)
Config.GUARD_TEMPLATES = {
	["Balerina Capucina"] = {
		Animations = {
			Idle = "rbxassetid://107989875822839",   -- Verified custom Idle
			Walk = "rbxassetid://111496778780434",   -- Verified custom Walk
		},
		MoveSpeed = 5,       -- Base movement speed (studs/sec)
		AttackRadius = 5.0,
	},

	["Guard_Default"] = {
		Animations = {
			Idle = "rbxassetid://107989875822839",
			Walk = "rbxassetid://111496778780434",
		},
		MoveSpeed = 12,
		AttackRadius = 5.0,
	},
}

-- Zone Floor Guard Placements & Level Progression (Zone -> TemplateName & Difficulty Modifiers)
Config.ZONE_GUARDS = {
	-- Default fallback for any floor without a custom entry
	DEFAULT = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 12,
		DetectionRadius = 35,
		AttackRadius = 5.0,
	},

	-- Zone 1: Sunny Start
	[1] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 12,
		DetectionRadius = 35,
		AttackRadius = 5.0,
	},

	-- Zone 2: Chaos Factory
	[2] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 13,
		DetectionRadius = 35,
		AttackRadius = 5.0,
	},

	-- Zone 3: Void Lunatic
	[3] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 14,
		DetectionRadius = 35,
		AttackRadius = 5.0,
	},

	-- Zone 4: Mechanical Works
	[4] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 15,
		DetectionRadius = 38,
		AttackRadius = 5.0,
	},

	-- Zone 5: Neon City (Dual Guards)
	[5] = {
		TemplateName = "Balerina Capucina",
		Count = 2,
		MoveSpeed = 15,
		DetectionRadius = 38,
		AttackRadius = 5.5,
	},

	-- Zone 6: Aquatica
	[6] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 16,
		DetectionRadius = 40,
		AttackRadius = 5.5,
	},

	-- Zone 7: Temple Of Ascension
	[7] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 16,
		DetectionRadius = 40,
		AttackRadius = 6.0,
	},

	-- Zone 8: Sky Kingdom
	[8] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 17,
		DetectionRadius = 42,
		AttackRadius = 6.0,
	},

	-- Zone 9: Mystic Realm
	[9] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 18,
		DetectionRadius = 42,
		AttackRadius = 6.5,
	},

	-- Zone 10: Hellfire
	[10] = {
		TemplateName = "Balerina Capucina",
		Count = 1,
		MoveSpeed = 19,
		DetectionRadius = 45,
		AttackRadius = 7.0,
	},
}

return Config
