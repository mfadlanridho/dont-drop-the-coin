--!nonstrict
--[[
    BankServer.luau
    Handles Bank Vault Pad touch detection, multi-vault support across map zones, Roblox Group loyalty gate validation, stack cashouts, leaderstats, and Safe Zone combat immunity.
    Location: src/server/Services/BankServer.luau (Syncs to ServerScriptService.Server.Services.BankServer)
--]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger"))

local log = Logger.create("Bank")

local Services = script.Parent
local DataStoreManager = require(Services:WaitForChild("DataStoreManager"))
local StackServer = require(Services:WaitForChild("StackServer"))

local BankServer = {}

-- Touch counter cache to prevent flickering TouchEnded log/FSM spam during walking animations
local PadTouches: { [BasePart]: { [Player]: number } } = {}

-- Validate Roblox Group Membership for Group Loyalty Vaults
local function checkGroupMembership(player: Player): boolean
	if not Config.GROUP_ID or Config.GROUP_ID == 0 then
		-- Placeholder Group ID 0: Allow Studio/Testing access
		return true
	end

	local success, isMember = pcall(function()
		return player:IsInGroup(Config.GROUP_ID)
	end)

	return success and isMember
end

-- Create leaderstats for a player
local function setupLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coinsVal = leaderstats:FindFirstChild("Coins") :: IntValue
	if not coinsVal then
		coinsVal = Instance.new("IntValue")
		coinsVal.Name = "Coins"
		coinsVal.Value = 0
		coinsVal.Parent = leaderstats
	end

	local stackVal = leaderstats:FindFirstChild("Stack") :: IntValue
	if not stackVal then
		stackVal = Instance.new("IntValue")
		stackVal.Name = "Stack"
		stackVal.Value = StackServer.GetStackCount(player)
		stackVal.Parent = leaderstats
	end

	-- Sync starting data from ProfileStore
	task.spawn(function()
		local data = DataStoreManager.GetData(player)
		if data and coinsVal then
			coinsVal.Value = data.Coins or 0
		end
		log(string.format("Leaderstats set up for %s (Coins: %d, Stack: %d)", player.Name, coinsVal.Value, stackVal.Value))
	end)
end

-- Update leaderstats display for player
function BankServer.UpdateLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsVal = leaderstats:FindFirstChild("Coins") :: IntValue
		local stackVal = leaderstats:FindFirstChild("Stack") :: IntValue

		local data = DataStoreManager.GetData(player)
		if data and coinsVal then
			coinsVal.Value = data.Coins or 0
		end
		if stackVal then
			stackVal.Value = StackServer.GetStackCount(player)
		end
	end
end

-- Bank Stack for Player at a Specific Vault Pad
function BankServer.BankStackAtVault(player: Player, vaultPad: BasePart?): boolean
	local stackCount = StackServer.GetStackCount(player)
	local vaultName = vaultPad and vaultPad.Name or "DefaultVault"

	if stackCount <= 0 then
		log(string.format("Player %s touched %s, but stack is 0.", player.Name, vaultName))
		return false
	end

	-- Check Group Membership if pad requires Group Loyalty
	if vaultPad and (vaultPad.Name == "GroupMemberVault" or vaultPad:GetAttribute("RequireGroup") == true) then
		if not checkGroupMembership(player) then
			log(string.format("BLOCKED: Player %s not in Roblox Group ID %s for %s", player.Name, tostring(Config.GROUP_ID), vaultName))
			return false
		end
	end

	-- Read vault pad attribute multiplier (default 1x)
	local multiplier = 1
	if vaultPad then
		multiplier = vaultPad:GetAttribute("Multiplier") or 1
	end
	if multiplier <= 0 then multiplier = 1 end

	local earnedCash = math.floor(stackCount * multiplier)
	DataStoreManager.AddBankedCash(player, earnedCash)

	-- Clear head stack & update stats
	StackServer.ClearStack(player)
	BankServer.UpdateLeaderstats(player)

	-- Fire client bank visualizer remote event & 2D banking audio
	local bankRemote = Remotes.Get("BankCoins")
	if bankRemote then
		bankRemote:FireClient(player, earnedCash, stackCount, multiplier)
	end

	local soundRemote = Remotes.Get("PlaySound")
	if soundRemote then
		soundRemote:FireClient(player, "BankCoins")
	end

	log(string.format("SUCCESS: Player %s BANKED %d coins for $%d cash at %s! (Multiplier: %.1fx)", player.Name, stackCount, earnedCash, vaultName, multiplier))
	return true
end

-- Bank Stack for Player (Default API)
function BankServer.BankStack(player: Player): boolean
	return BankServer.BankStackAtVault(player, nil)
end

-- Bind a Vault Pad with Touch Listeners & Debounce Counter
local function bindVaultPad(pad: BasePart)
	if pad:GetAttribute("_vault_bound") then return end
	pad:SetAttribute("_vault_bound", true)

	PadTouches[pad] = {}

	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Check Group Membership for Group Member Vault
		if pad.Name == "GroupMemberVault" or pad:GetAttribute("RequireGroup") == true then
			if not checkGroupMembership(player) then
				return
			end
		end

		local touchMap = PadTouches[pad]
		local prevCount = touchMap[player] or 0
		touchMap[player] = prevCount + 1

		-- FSM State transition & cashout ONLY on initial entry (prevCount == 0)
		if prevCount == 0 then
			if PlayerFSM.GetState(player) == "Normal" then
				PlayerFSM.SetState(player, "SafeZone")
				log(string.format("Player %s entered SafeZone on %s", player.Name, pad.Name))
			end
			BankServer.BankStackAtVault(player, pad)
		end
	end)

	pad.TouchEnded:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local touchMap = PadTouches[pad]
		if not touchMap then return end

		local currentCount = touchMap[player] or 0
		if currentCount > 0 then
			currentCount -= 1
			touchMap[player] = currentCount
		end

		-- Reset FSM state back to Normal ONLY on final exit (currentCount == 0)
		if currentCount <= 0 then
			touchMap[player] = nil
			if PlayerFSM.GetState(player) == "SafeZone" then
				PlayerFSM.SetState(player, "Normal")
				log(string.format("Player %s exited SafeZone on %s", player.Name, pad.Name))
			end
		end
	end)

	log(string.format("Bound Vault Pad: %s (Multiplier: %.1fx, RequireGroup: %s)", pad.Name, pad:GetAttribute("Multiplier") or 1, tostring(pad:GetAttribute("RequireGroup") or (pad.Name == "GroupMemberVault"))))
end

-- Initialize Service
function BankServer.Init()
	-- Set up leaderstats for players
	Players.PlayerAdded:Connect(function(player)
		setupLeaderstats(player)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		setupLeaderstats(p)
	end

	-- Scan Workspace.BankVaults folder
	local function scanVaultsFolder(folder: Instance)
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("BasePart") then
				bindVaultPad(child)
			end
		end
		folder.ChildAdded:Connect(function(child)
			if child:IsA("BasePart") then
				bindVaultPad(child)
			end
		end)
	end

	local vaultsFolder = Workspace:FindFirstChild("BankVaults")
	if vaultsFolder then
		scanVaultsFolder(vaultsFolder)
	end

	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "BankVaults" then
			scanVaultsFolder(child)
		end
	end)

	-- Also support CollectionService tagged pads ("BankVault")
	for _, instance in ipairs(CollectionService:GetTagged("BankVault")) do
		if instance:IsA("BasePart") then
			bindVaultPad(instance)
		end
	end
	CollectionService:GetInstanceAddedSignal("BankVault"):Connect(function(instance)
		if instance:IsA("BasePart") then
			bindVaultPad(instance)
		end
	end)

	local bankRemote = Remotes.Get("BankCoins")
	if bankRemote then
		bankRemote.OnServerEvent:Connect(function(player)
			log(string.format("BankCoins remote event received from player %s", player.Name))
			BankServer.BankStack(player)
		end)
	end

	log("BankServer initialized successfully with debounced touch handling.")
end

return BankServer
