--!strict
--[[
    HUDController.luau
    Client controller listening to leaderstats.Stack and leaderstats.Coins value changes and updating WalletFrame in real-time.
    Location: src/client/Controllers/HUDController.luau
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HUDController = {}

local function setupLeaderstatsListeners(playerGui: PlayerGui, leaderstats: Folder)
	local hudGui = playerGui:WaitForChild("HUDGui", 10) :: ScreenGui?
	if not hudGui then return end

	local walletFrame = hudGui:WaitForChild("WalletFrame", 10) :: Frame?
	if not walletFrame then return end

	local coinsLabel = walletFrame:WaitForChild("CoinsLabel", 10) :: TextLabel?
	local bankedLabel = walletFrame:WaitForChild("BankedLabel", 10) :: TextLabel?

	-- 1. Sync Current Stack (Coins on Head)
	local stackVal = leaderstats:WaitForChild("Stack", 5) :: NumberValue?
	if stackVal and coinsLabel then
		local function updateStack()
			coinsLabel.Text = "COINS: " .. tostring(stackVal.Value)
		end
		stackVal.Changed:Connect(updateStack)
		updateStack()
	end

	-- 2. Sync Banked Coins (Banked Cash)
	local coinsVal = leaderstats:WaitForChild("Coins", 5) :: NumberValue?
	if coinsVal and bankedLabel then
		local function updateBanked()
			bankedLabel.Text = "BANKED: $" .. tostring(coinsVal.Value)
		end
		coinsVal.Changed:Connect(updateBanked)
		updateBanked()
	end

	print("[HUDController] WalletFrame real-time leaderstats listeners initialized successfully!")
end

function HUDController.Init()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10) :: Folder?

	if leaderstats then
		setupLeaderstatsListeners(playerGui, leaderstats)
	else
		LocalPlayer.ChildAdded:Connect(function(child)
			if child.Name == "leaderstats" and child:IsA("Folder") then
				setupLeaderstatsListeners(playerGui, child)
			end
		end)
	end
end

return HUDController
