--!nonstrict
--[[
    StackServer.luau
    Manages server-side player head stack state, tracks per-coin zone tiers,
    computes cumulative stack weight, applies dynamic WalkSpeed encumbrance,
    updates leaderstats.Stack, and replicates stack data to clients.
    Location: src/server/Services/StackServer.luau (Syncs to ServerScriptService.Server.Services.StackServer)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

type StackData = {
	Count: number,
	TotalWeight: number,
	Coins: { number }, -- Array of ZoneTier integers (e.g. {1, 1, 2, 5})
}

local PlayerStacks: { [number]: StackData } = {}
local StackServer = {}

--- Resolves the weight of a coin based on its zone tier in Config
local function getCoinWeight(tier: number): number
	local tierData = Config.ZONE_TIERS and Config.ZONE_TIERS[tier]
	if tierData and tierData.Weight then
		return tierData.Weight
	end
	return 1.0
end

--- Calculates the encumbered WalkSpeed given the player's total stack weight
local function calculateWalkSpeed(totalWeight: number): number
	local encCfg = Config.ENCUMBRANCE or {}
	local baseSpeed = encCfg.BASE_WALKSPEED or 16
	local minSpeed = encCfg.MIN_WALKSPEED or 8
	local penaltyFactor = encCfg.WEIGHT_PENALTY_FACTOR or 0.02

	local speed = baseSpeed * (1 - (totalWeight * penaltyFactor))
	return math.clamp(speed, minSpeed, baseSpeed)
end

--- Applies the encumbered WalkSpeed to the player's Humanoid
local function applyEncumbranceSpeed(player: Player, totalWeight: number)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = calculateWalkSpeed(totalWeight)
		end
	end
end

--- Helper to get or create stack entry for a player
local function getOrCreateStack(userId: number): StackData
	if not PlayerStacks[userId] then
		PlayerStacks[userId] = {
			Count = 0,
			TotalWeight = 0,
			Coins = {},
		}
	end
	return PlayerStacks[userId]
end

--- Helper to sync leaderstats.Stack IntValue
local function syncLeaderstatsStack(player: Player, count: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stackVal = leaderstats:FindFirstChild("Stack") :: IntValue
		if stackVal then
			stackVal.Value = count
		end
	end
end

--- Adds coin(s) of a specific zone tier to the player's stack and recalculates encumbrance
function StackServer.AddCoin(player: Player, zoneTier: number?, count: number?): number
	local userId = player.UserId
	local stackData = getOrCreateStack(userId)

	local tier = math.clamp(zoneTier or 1, 1, 10)
	local coinCount = math.max(1, count or 1)
	local coinWeight = getCoinWeight(tier)

	for _ = 1, coinCount do
		table.insert(stackData.Coins, tier)
		stackData.TotalWeight += coinWeight
	end
	stackData.Count = #stackData.Coins

	-- Apply dynamic encumbrance speed penalty
	applyEncumbranceSpeed(player, stackData.TotalWeight)

	-- Replicate Stack Update to All Clients & Leaderstats
	syncLeaderstatsStack(player, stackData.Count)

	local updateEvent = Remotes.Get("UpdateStack")
	if updateEvent then
		updateEvent:FireAllClients(player, stackData.Count, stackData.TotalWeight, stackData.Coins)
	end

	return stackData.Count
end

--- Centralized API to process any coin pickup across the game engine (awards coins & plays pitch combo audio)
function StackServer.AwardCoinPickup(player: Player, zoneTierOrAmount: number?, originPart: BasePart?): number
	local newStack = StackServer.AddCoin(player, zoneTierOrAmount or 1, 1)

	local soundRemote = Remotes.Get("PlaySound")
	if soundRemote then
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		soundRemote:FireClient(player, "CoinPickupCombo", hrp or originPart)
	end

	return newStack
end

--- Sets explicit stack count with a given default tier (used for spawning and debug)
function StackServer.SetStackCount(player: Player, count: number, defaultTier: number?): number
	local userId = player.UserId
	local stackData = getOrCreateStack(userId)

	local newCount = math.max(0, count)
	local tier = math.clamp(defaultTier or 1, 1, 10)
	local coinWeight = getCoinWeight(tier)

	table.clear(stackData.Coins)
	stackData.TotalWeight = 0
	for _ = 1, newCount do
		table.insert(stackData.Coins, tier)
		stackData.TotalWeight += coinWeight
	end
	stackData.Count = #stackData.Coins

	-- Apply dynamic encumbrance speed penalty
	applyEncumbranceSpeed(player, stackData.TotalWeight)

	syncLeaderstatsStack(player, stackData.Count)

	local updateEvent = Remotes.Get("UpdateStack")
	if updateEvent then
		updateEvent:FireAllClients(player, stackData.Count, stackData.TotalWeight, stackData.Coins)
	end

	return stackData.Count
end

--- Clears player stack (used on banking or ragdoll explosion) and restores base walk speed
function StackServer.ClearStack(player: Player): (number, { number })
	local userId = player.UserId
	local stackData = PlayerStacks[userId]
	local previousCount = 0
	local previousCoins = {}

	if stackData then
		previousCount = stackData.Count
		previousCoins = table.clone(stackData.Coins)
		table.clear(stackData.Coins)
		stackData.Count = 0
		stackData.TotalWeight = 0
	end

	-- Restore standard walk speed
	applyEncumbranceSpeed(player, 0)

	syncLeaderstatsStack(player, 0)

	local updateEvent = Remotes.Get("UpdateStack")
	if updateEvent then
		updateEvent:FireAllClients(player, 0, 0, {})
	end

	return previousCount, previousCoins
end

--- Returns the current coin count in the player's stack
function StackServer.GetStackCount(player: Player): number
	local stackData = PlayerStacks[player.UserId]
	return stackData and stackData.Count or 0
end

--- Returns the current total weight of coins in the player's stack
function StackServer.GetStackWeight(player: Player): number
	local stackData = PlayerStacks[player.UserId]
	return stackData and stackData.TotalWeight or 0
end

--- Returns a list of all coin zone tiers currently in the player's stack
function StackServer.GetCoins(player: Player): { number }
	local stackData = PlayerStacks[player.UserId]
	if stackData and stackData.Coins then
		return table.clone(stackData.Coins)
	end
	return {}
end

--- Clean up on player leave and sync initial stacks
function StackServer.Init()
	Players.PlayerRemoving:Connect(function(player)
		PlayerStacks[player.UserId] = nil
	end)

	local function onCharacterSpawned(player: Player)
		-- Start player with initial coins configured in Config.INITIAL_STACK_COUNT
		task.defer(function()
			StackServer.SetStackCount(player, Config.INITIAL_STACK_COUNT or 3, 1)
		end)
	end

	local function onPlayerJoined(player: Player)
		player.CharacterAdded:Connect(function()
			onCharacterSpawned(player)
		end)
		if player.Character then
			onCharacterSpawned(player)
		end
	end

	Players.PlayerAdded:Connect(onPlayerJoined)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayerJoined(p)
	end

	print("[StackServer] Initialized with coin tier tracking & dynamic WalkSpeed encumbrance.")
end

return StackServer
