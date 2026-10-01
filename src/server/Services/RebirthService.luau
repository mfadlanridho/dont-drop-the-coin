--!nonstrict
--[[
    RebirthService.luau
    Master server service managing player Rebirth progression, requirements evaluation,
    atomic profile reset execution, reward distribution, and multi-service event dispatching.
    Location: src/server/Services/RebirthService.luau (Syncs to ServerScriptService.Server.Services.RebirthService)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal = require(Packages:WaitForChild("SignalModule"))
local Logger = require(Packages:WaitForChild("LoggerModule"))
local RebirthModule = require(Packages:WaitForChild("RebirthModule") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RebirthConfig = require(Shared:WaitForChild("Config"):WaitForChild("RebirthConfig") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes"))

local Services = script.Parent
local DataStoreManager = require(Services:WaitForChild("DataStoreManager"))
local StackServer = require(Services:WaitForChild("StackServer"))

local log = Logger.create("Rebirth")

local RebirthService = {}
RebirthService.OnRebirth = Signal.new() :: Signal.Signal<Player, number, number> -- (player, newRebirthLevel, multiplier)

local processingPlayers: { [Player]: boolean } = {}

--- Returns current rebirth level for player
function RebirthService.GetRebirths(player: Player): number
	local data = DataStoreManager.GetData(player)
	if data and data.Rebirths then
		return data.Rebirths
	end
	return 0
end

--- Returns active cashout multiplier for player derived from rebirth count
function RebirthService.GetMultiplier(player: Player): number
	local rebirthCount = RebirthService.GetRebirths(player)
	return RebirthModule.GetMultiplier(RebirthConfig, rebirthCount)
end

--- Evaluates requirements and progress for player
function RebirthService.GetEvaluation(player: Player): RebirthModule.RequirementResult?
	local data = DataStoreManager.GetData(player)
	if not data then return nil end
	local currentRebirth = data.Rebirths or 0
	return RebirthModule.Evaluate(RebirthConfig, currentRebirth, data)
end

--- Checks if player is currently eligible to rebirth
function RebirthService.CanRebirth(player: Player): (boolean, string?)
	if processingPlayers[player] then
		return false, "AlreadyProcessing"
	end

	local data = DataStoreManager.GetData(player)
	if not data then
		return false, "DataNotLoaded"
	end

	local currentRebirth = data.Rebirths or 0
	local maxRebirth = RebirthConfig.MaxRebirth or 50
	if currentRebirth >= maxRebirth then
		return false, "MaxRebirthReached"
	end

	local eval = RebirthModule.Evaluate(RebirthConfig, currentRebirth, data)
	if not eval.AllMet then
		return false, "RequirementsNotMet"
	end

	if RebirthConfig.CanRebirthPredicate then
		local allowed, reason = RebirthConfig.CanRebirthPredicate(player, data)
		if not allowed then
			return false, reason or "CustomPredicateFailed"
		end
	end

	return true, nil
end

--- Syncs rebirth status and evaluation to client
function RebirthService.SyncClient(player: Player)
	if not player or not player.Parent then return end
	local data = DataStoreManager.GetData(player)
	if not data then return end

	local currentRebirth = data.Rebirths or 0
	local eval = RebirthModule.Evaluate(RebirthConfig, currentRebirth, data)
	local multiplier = RebirthService.GetMultiplier(player)

	local updateRemote = Remotes.Get("RebirthDataUpdated")
	if updateRemote then
		updateRemote:FireClient(player, {
			CurrentRebirth = currentRebirth,
			Multiplier = multiplier,
			Evaluation = eval,
		})
	end
end

--- Executes the rebirth reset and reward distribution
function RebirthService.ExecuteRebirth(player: Player): (boolean, string?)
	local canRebirth, reason = RebirthService.CanRebirth(player)
	if not canRebirth then
		log(string.format("Rebirth rejected for %s: %s", player.Name, tostring(reason)))
		return false, reason
	end

	processingPlayers[player] = true

	local data = DataStoreManager.GetData(player)
	local oldRebirth = data.Rebirths or 0
	local newRebirth = oldRebirth + 1

	-- 1. Apply Reset Schema
	if RebirthConfig.ResetCallback then
		RebirthConfig.ResetCallback(data)
	else
		data.Coins = 0
	end

	-- 2. Apply Rewards
	if RebirthConfig.RewardCallback then
		RebirthConfig.RewardCallback(player, newRebirth, data)
	else
		data.Rebirths = newRebirth
	end

	-- 3. Reset In-Game Physics / Stack
	if StackServer and typeof(StackServer.ClearStack) == "function" then
		StackServer.ClearStack(player)
	end
	if StackServer and typeof(StackServer.SetStackCount) == "function" then
		StackServer.SetStackCount(player, Config.INITIAL_STACK_COUNT or 3)
	end

	-- 4. Update Leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsVal = leaderstats:FindFirstChild("Coins") :: IntValue?
		if coinsVal then
			coinsVal.Value = data.Coins or 0
		end

		local rebirthsVal = leaderstats:FindFirstChild("Rebirths") :: IntValue?
		if rebirthsVal then
			rebirthsVal.Value = newRebirth
		end

		local stackVal = leaderstats:FindFirstChild("Stack") :: IntValue?
		if stackVal and StackServer then
			stackVal.Value = StackServer.GetStackCount(player)
		end
	end

	-- 5. Sync Data Store dirty state
	DataStoreManager.SetCoins(player, data.Coins or 0)

	local newMultiplier = RebirthModule.GetMultiplier(RebirthConfig, newRebirth)

	-- 6. Fire System-wide signals
	RebirthService.OnRebirth:Fire(player, newRebirth, newMultiplier)

	-- 7. Fire Remotes to Client for Celebration / UI
	local successRemote = Remotes.Get("RebirthSuccess")
	if successRemote then
		successRemote:FireClient(player, {
			NewRebirth = newRebirth,
			Multiplier = newMultiplier,
		})
	end

	-- Sync updated data
	RebirthService.SyncClient(player)

	processingPlayers[player] = nil
	log(string.format("🌟 Rebirth successful for %s! Level %d -> %d (Multiplier: %.2fx)", player.Name, oldRebirth, newRebirth, newMultiplier))
	return true, nil
end

function RebirthService.Init()
	-- Listen for client request to rebirth
	local requestRemote = Remotes.Get("RequestRebirth")
	if requestRemote then
		requestRemote.OnServerEvent:Connect(function(player: Player)
			RebirthService.ExecuteRebirth(player)
		end)
	end

	-- Sync on player join and data load
	local function onPlayerJoined(player: Player)
		DataStoreManager.OnPlayerLoaded(player, function(data)
			task.defer(function()
				RebirthService.SyncClient(player)
			end)
		end)
	end

	Players.PlayerAdded:Connect(onPlayerJoined)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayerJoined(p)
	end

	log("RebirthService initialized successfully!")
end

return RebirthService
