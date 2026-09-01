--!nonstrict
--[[
    CoinService.luau
    Master server service managing all coin collection logic, anti-cheat distance checks,
    node respawning, dropped loot destruction, and audio replication across the game engine.
    Location: src/server/Services/CoinService.luau (Syncs to ServerScriptService.Server.Services.CoinService)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Services = script.Parent
local StackServer = require(Services:WaitForChild("StackServer"))

local CoinService = {}

--- Replicates pitch combo audio to client
local function playPickupAudio(player: Player, originPart: BasePart?)
	local soundRemote = Remotes.Get("PlaySound")
	if soundRemote then
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		soundRemote:FireClient(player, "CoinPickupCombo", hrp or originPart)
	end
end

--- Centralized API: Collects an arena coin node (with anti-cheat distance validation & auto-respawn)
function CoinService.CollectArenaNode(player: Player, coinNode: BasePart): boolean
	if not coinNode or not coinNode:IsA("BasePart") or not coinNode:GetAttribute("Active") then
		return false
	end

	local character = player.Character
	if not character then return false end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return false end

	-- Server Anti-Cheat Distance Validation (15 studs max)
	local distance = (hrp.Position - coinNode.Position).Magnitude
	if distance > 15 then
		warn(string.format("[Anti-Cheat] %s attempted node pickup from invalid distance: %.2f studs", player.Name, distance))
		return false
	end

	-- Deactivate Node
	coinNode:SetAttribute("Active", false)
	coinNode.Transparency = 1
	coinNode.CanTouch = false

	-- Award Stack & Play Audio
	local zoneTier = coinNode:GetAttribute("ZoneTier") or 1
	local newStack = StackServer.AddCoin(player, zoneTier)
	playPickupAudio(player, coinNode)

	print(string.format("[CoinService] %s collected Arena Node in Zone %d (New Stack: %d)", player.Name, zoneTier, newStack))

	-- Respawn Timer (5 seconds)
	task.delay(Config.COIN_NODE_RESPAWN_TIME or 5, function()
		if coinNode and coinNode.Parent then
			coinNode:SetAttribute("Active", true)
			coinNode.Transparency = 0
			coinNode.CanTouch = true
		end
	end)

	return true
end

--- Centralized API: Collects a physical dropped loot coin (with connection cleanup & part destruction)
function CoinService.CollectDroppedLoot(player: Player, coin: BasePart, touchConnection: RBXScriptConnection?): boolean
	if not coin or not coin.Parent then return false end

	if touchConnection then
		touchConnection:Disconnect()
	end

	local newStack = StackServer.AddCoin(player, 1)
	playPickupAudio(player, coin)

	print(string.format("[CoinService] %s collected Dropped Loot (New Stack: %d)", player.Name, newStack))

	coin:Destroy()
	return true
end

--- Centralized API: Universal bonus coin award (for AFK rewards, daily spins, monetization)
function CoinService.AwardBonus(player: Player, amount: number, originPart: BasePart?): number
	local coins = math.max(1, amount or 1)
	local newStack = StackServer.AddCoin(player, coins)
	playPickupAudio(player, originPart)

	print(string.format("[CoinService] Awarded %d Bonus Coins to %s (New Stack: %d)", coins, player.Name, newStack))
	return newStack
end

function CoinService.Init()
	print("[CoinService] Master Coin Collection & Anti-Cheat Service initialized successfully.")
end

return CoinService
