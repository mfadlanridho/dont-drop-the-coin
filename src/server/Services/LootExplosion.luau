--!nonstrict
--[[
    LootExplosion.luau
    Handles stack detachment and physical unanchored coin scattering in 360-degree radial arc.
    Delegates dropped coin collection and audio replication to CoinService.luau.
    Location: src/server/Services/LootExplosion.luau (Syncs to ServerScriptService.Server.Services.LootExplosion)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TemplateUtil = require(Shared:WaitForChild("Utils"):WaitForChild("TemplateUtil"))

local Services = script.Parent
local StackServer = require(Services:WaitForChild("StackServer"))
local CoinService = require(Services:WaitForChild("CoinService"))

local DroppedCoinsFolder: Folder
local LootExplosion = {}

-- Create Unanchored Dropped Coin Part by cloning CoinTemplate
local function createDroppedCoin(zoneTier: number): Part
	local coin = TemplateUtil.CloneCoinTemplate() :: Part
	coin.Name = "DroppedLootCoin"
	coin.Anchored = false -- Physical unanchored bouncing part!
	coin.CanCollide = true
	coin.CanTouch = true
	coin:SetAttribute("ZoneTier", zoneTier)

	-- Apply Zone Tier Color if configured
	local tierData = Config.ZONE_TIERS and Config.ZONE_TIERS[zoneTier]
	if tierData and tierData.Color then
		coin.Color = tierData.Color
	end

	return coin
end

-- Explode Stack Coins in 360 Arc
function LootExplosion.ScatterCoins(player: Player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	local coins = StackServer.GetCoins(player)
	local coinsToScatter = #coins
	if coinsToScatter <= 0 then
		coinsToScatter = StackServer.GetStackCount(player)
		if coinsToScatter <= 0 then return end
	end

	-- Clear player stack (restores normal WalkSpeed)
	StackServer.ClearStack(player)

	local originPos = hrp.Position + Vector3.new(0, 4, 0)
	local despawnTime = Config.DESPAWN_DROPPED_COIN_TIME or 15

	for i = 1, coinsToScatter do
		local zoneTier = coins[i] or 1
		local coin = createDroppedCoin(zoneTier)
		coin.Position = originPos
		coin.Parent = DroppedCoinsFolder

		-- Calculate 360-degree outward radial velocity vector
		local angle = ((i - 1) / math.max(1, coinsToScatter)) * (math.pi * 2)
		local speed = math.random(15, 30)
		local upwardForce = math.random(25, 45)
		local direction = Vector3.new(math.cos(angle) * speed, upwardForce, math.sin(angle) * speed)

		coin.AssemblyLinearVelocity = direction
		coin.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))

		local touchConnection: RBXScriptConnection?

		-- Touch pickup listener for dropped coins (with 1.0s pickup delay so coins fly outward first!)
		task.delay(1.0, function()
			if not coin or not coin.Parent then return end
			touchConnection = coin.Touched:Connect(function(hit)
				local hitChar = hit.Parent
				local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
				if hitPlayer then
					CoinService.CollectDroppedLoot(hitPlayer, coin, touchConnection)
				end
			end)
		end)

		-- Despawn timer
		task.delay(despawnTime, function()
			if coin and coin.Parent then
				if touchConnection then
					touchConnection:Disconnect()
					touchConnection = nil
				end
				coin:Destroy()
			end
		end)
	end

	print(string.format("[LootExplosion] Exploded %d stack coins for %s!", coinsToScatter, player.Name))
end

-- Initialize Dropped Coins Folder
function LootExplosion.Init()
	local existingFolder = Workspace:FindFirstChild("DroppedCoins") :: Folder?
	if not existingFolder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "DroppedCoins"
		newFolder.Parent = Workspace
		DroppedCoinsFolder = newFolder
	else
		DroppedCoinsFolder = existingFolder
	end

	print("[LootExplosion] Initialized dropped coins scatter service.")
end

return LootExplosion
