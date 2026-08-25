--!nonstrict
--[[
    LootExplosion.luau
    Handles stack detachment and physical unanchored coin scattering in 360-degree radial arc.
    Location: src/server/Services/LootExplosion.luau (Syncs to ServerScriptService.Server.Services.LootExplosion)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Services = script.Parent
local StackServer = require(Services:WaitForChild("StackServer"))

local DroppedCoinsFolder: Folder
local LootExplosion = {}

-- Create Unanchored Dropped Coin Part
local function createDroppedCoin(): Part
	local coin = Instance.new("Part")
	coin.Name = "DroppedLootCoin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.4, 2.0, 2.0)
	coin.Color = Color3.fromRGB(255, 223, 0) -- Glowing Gold
	coin.Material = Enum.Material.Neon
	coin.Anchored = false -- Physical unanchored bouncing part!
	coin.CanCollide = true
	coin.CanTouch = true
	coin.Orientation = Vector3.new(0, 0, 90)
	return coin
end

-- Explode Stack Coins in 360 Arc
function LootExplosion.ScatterCoins(player: Player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	local stackCount = StackServer.GetStackCount(player)
	if stackCount <= 0 then return end

	-- Clear player's head stack
	StackServer.ClearStack(player)

	-- Limit physical scatter parts to prevent lag (max 15 physical dropped parts per explosion)
	local scatterCount = math.min(stackCount, 15)

	for _ = 1, scatterCount do
		local coin = createDroppedCoin()
		coin.Position = hrp.Position + Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))
		coin.Parent = DroppedCoinsFolder

		-- Apply 360 radial impulse vector
		local impulse = Vector3.new(
			math.random(-30, 30),
			math.random(20, 45),
			math.random(-30, 30)
		)
		coin:ApplyImpulse(impulse)

		-- Pickup listener for nearby players
		local touchedConnection
		touchedConnection = coin.Touched:Connect(function(hit)
			local touchChar = hit.Parent
			local picker = Players:GetPlayerFromCharacter(touchChar)
			if picker and picker ~= player then
				touchedConnection:Disconnect()
				StackServer.AddCoin(picker, 1)
				coin:Destroy()
			end
		end)

		-- Despawn after 10 seconds
		task.delay(Config.DESPAWN_DROPPED_COIN_TIME, function()
			if coin and coin.Parent then
				coin:Destroy()
			end
		end)
	end

	print(string.format("[LootExplosion] Exploded %d stack coins for %s!", stackCount, player.Name))
end

-- Initialize Folder
function LootExplosion.Init()
	DroppedCoinsFolder = Workspace:FindFirstChild("DroppedLootCoins") :: Folder
	if not DroppedCoinsFolder then
		DroppedCoinsFolder = Instance.new("Folder")
		DroppedCoinsFolder.Name = "DroppedLootCoins"
		DroppedCoinsFolder.Parent = Workspace
	end
end

return LootExplosion
