--!nonstrict
--[[
    UpgradeService.luau
    Master server service managing permanent player stat upgrades (Speed, Strength, Jump).
    Handles purchase validation, coin deduction, ProfileStore persistence, and live Humanoid stat application.
    Location: src/server/Services/UpgradeService.luau (Syncs to ServerScriptService.Server.Services.UpgradeService)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Services = script.Parent
local DataStoreManager = require(Services:WaitForChild("DataStoreManager"))
local BankServer = require(Services:WaitForChild("BankServer"))
local StackServer = require(Services:WaitForChild("StackServer"))

local UpgradeService = {}

--- Returns the active upgrade levels for a player
function UpgradeService.GetUpgrades(player: Player): { [string]: number }
	local data = DataStoreManager.GetData(player)
	if data and data.Upgrades then
		return data.Upgrades
	end
	return {
		SpeedLevel = 1,
		StrengthLevel = 1,
		JumpLevel = 1,
	}
end

--- Returns cumulative stat bonuses derived from current upgrade levels
function UpgradeService.GetModifiers(player: Player): { BonusSpeed: number, WeightDiscount: number, BonusJump: number }
	local upgrades = UpgradeService.GetUpgrades(player)
	local speedLvl = math.clamp(upgrades.SpeedLevel or 1, 1, #Config.UPGRADES.Speed.Levels)
	local strengthLvl = math.clamp(upgrades.StrengthLevel or 1, 1, #Config.UPGRADES.Strength.Levels)
	local jumpLvl = math.clamp(upgrades.JumpLevel or 1, 1, #Config.UPGRADES.Jump.Levels)

	local speedData = Config.UPGRADES.Speed.Levels[speedLvl]
	local strengthData = Config.UPGRADES.Strength.Levels[strengthLvl]
	local jumpData = Config.UPGRADES.Jump.Levels[jumpLvl]

	return {
		BonusSpeed = (speedData and speedData.BonusSpeed) or 0,
		WeightDiscount = (strengthData and strengthData.WeightDiscount) or 0,
		BonusJump = (jumpData and jumpData.BonusJump) or 0,
	}
end

--- Applies live stat modifiers (JumpHeight, JumpPower, and encumbered WalkSpeed) to player's character
function UpgradeService.ApplyStats(player: Player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local mods = UpgradeService.GetModifiers(player)
	local baseJumpHeight = 7.2
	local baseJumpPower = 50

	-- Safely apply Jump upgrades to both JumpHeight and JumpPower
	humanoid.JumpHeight = baseJumpHeight + mods.BonusJump
	humanoid.JumpPower = baseJumpPower + (mods.BonusJump * 6)

	-- Recalculate WalkSpeed taking into account both current stack weight and upgrades
	StackServer.RecalculateEncumbrance(player)
end

--- Purchases the next tier for a given stat category
function UpgradeService.BuyUpgrade(player: Player, statCategory: string): (boolean, string?)
	local statCfg = Config.UPGRADES[statCategory]
	if not statCfg then
		return false, "InvalidStatCategory"
	end

	local data = DataStoreManager.GetData(player)
	if not data then
		return false, "DataNotLoaded"
	end

	if not data.Upgrades then
		data.Upgrades = {
			SpeedLevel = 1,
			StrengthLevel = 1,
			JumpLevel = 1,
		}
	end

	local statKey = statCfg.StatKey
	local currentLvl = data.Upgrades[statKey] or 1
	local maxLevel = #statCfg.Levels

	if currentLvl >= maxLevel then
		return false, "AlreadyMaxLevel"
	end

	local nextLvl = currentLvl + 1
	local lvlData = statCfg.Levels[nextLvl]
	if not lvlData then
		return false, "LevelConfigMissing"
	end

	local cost = lvlData.Cost or 0
	local currentCoins = data.Coins or 0

	if currentCoins < cost then
		return false, "InsufficientCoins"
	end

	-- Deduct coins and update level
	local success = DataStoreManager.RemoveCoins(player, cost)
	if not success then
		return false, "DeductionFailed"
	end

	data.Upgrades[statKey] = nextLvl
	BankServer.UpdateLeaderstats(player)

	-- Apply stats to live character
	UpgradeService.ApplyStats(player)

	-- Sync state to client
	local updateRemote = Remotes.Get("UpdateUpgrades")
	if updateRemote then
		updateRemote:FireClient(player, data.Upgrades)
	end

	-- Toast Notification & Audio
	local notifRemote = Remotes.Get("SendNotification")
	if notifRemote then
		notifRemote:FireClient(player, {
			Title = "🎉 UPGRADE UNLOCKED!",
			Description = string.format("%s %s upgraded to Lv. %d!", statCfg.Icon or "", statCfg.DisplayName, nextLvl),
			Duration = 4.0,
			Color = Color3.fromRGB(0, 230, 150),
		})
	end

	local soundRemote = Remotes.Get("PlaySound")
	if soundRemote then
		soundRemote:FireClient(player, "BankCoins")
	end

	print(string.format("[UpgradeService] %s purchased %s Lv. %d for $%d cash!", player.Name, statCfg.DisplayName, nextLvl, cost))
	return true, nil
end

--- Resets all upgrades to Level 1 (for testing & developer debug)
function UpgradeService.ResetUpgrades(player: Player)
	local data = DataStoreManager.GetData(player)
	if data then
		data.Upgrades = {
			SpeedLevel = 1,
			StrengthLevel = 1,
			JumpLevel = 1,
		}
		UpgradeService.ApplyStats(player)
		local updateRemote = Remotes.Get("UpdateUpgrades")
		if updateRemote then
			updateRemote:FireClient(player, data.Upgrades)
		end
		print(string.format("[UpgradeService] Reset all upgrades to Level 1 for %s", player.Name))
	end
end

function UpgradeService.Init()
	-- BuyUpgrade remote listener
	local buyRemote = Remotes.Get("BuyUpgrade")
	if buyRemote then
		buyRemote.OnServerEvent:Connect(function(player: Player, statCategory: string)
			if statCategory == "Reset" then
				UpgradeService.ResetUpgrades(player)
			else
				UpgradeService.BuyUpgrade(player, statCategory)
			end
		end)
	end

	-- Apply stats on character spawn
	local function onCharacterSpawned(player: Player)
		task.defer(function()
			UpgradeService.ApplyStats(player)
		end)
	end

	local function onPlayerJoined(player: Player)
		player.CharacterAdded:Connect(function()
			onCharacterSpawned(player)
		end)
		if player.Character then
			onCharacterSpawned(player)
		end

		DataStoreManager.OnPlayerLoaded(player, function(data)
			if data and data.Upgrades then
				local updateRemote = Remotes.Get("UpdateUpgrades")
				if updateRemote then
					updateRemote:FireClient(player, data.Upgrades)
				end
			end
			UpgradeService.ApplyStats(player)
		end)
	end

	Players.PlayerAdded:Connect(onPlayerJoined)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayerJoined(p)
	end

	print("[UpgradeService] Permanent Stat Upgrades Service initialized successfully.")
end

return UpgradeService
