-- ShopSystem Client Script
-- Scans Shop.ScrollingFrame for Buy frames, fetches live Robux prices, and binds purchase prompts
-- Place in: src/client/Shop/ShopSystem.client.luau -> StarterPlayer.StarterPlayerScripts.Client.Shop.ShopSystem

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIFolder = SharedFolder:WaitForChild("UI")
local ButtonFunctionality = require(UIFolder:WaitForChild("ButtonFunctionality"))
local OpenFrame = require(UIFolder:WaitForChild("OpenFrame"))

local PromptService = require(script.Parent.Parent:WaitForChild("Monetization"):WaitForChild("PromptService"))

-- PRODUCT ALIAS / NAME MAP
local PRODUCT_NAME_MAP = {
	["SuperGlueCard"] = "Super Glue",
	["MegaDashCard"] = "Mega Dash Range",
	["InstantBankCard"] = "Instant Bank",
	["NuclearRevengeCard"] = "Nuclear Revenge",
	["GachaSkinRollCard"] = "Gacha Skin Roll",
}

local function getOfferForFrame(buyFrame)
	if not buyFrame then return nil end

	-- 1. Check StringValue 'Product' inside buyFrame
	local productVal = buyFrame:FindFirstChild("Product")
	if productVal and productVal:IsA("StringValue") and productVal.Value ~= "" then
		local val = productVal.Value
		local offer = PromptService.getOfferByKey(val) or PromptService.getOfferByLegacyName(val)
		if offer then return offer end
	end

	-- 2. Check Attributes on buyFrame or parent card frame
	local parentFrame = buyFrame.Parent
	for _, inst in ipairs({ buyFrame, parentFrame }) do
		if inst then
			local keyAttr = inst:GetAttribute("OfferKey") or inst:GetAttribute("ProductName")
			if keyAttr then
				local offer = PromptService.getOfferByKey(tostring(keyAttr)) or PromptService.getOfferByLegacyName(tostring(keyAttr))
				if offer then return offer end
			end
		end
	end

	-- 3. Check Parent card frame name via PRODUCT_NAME_MAP
	if parentFrame then
		local frameName = parentFrame.Name
		local mappedName = PRODUCT_NAME_MAP[frameName] or frameName
		local offer = PromptService.getOfferByKey(frameName)
			or PromptService.getOfferByLegacyName(mappedName)
			or PromptService.getOfferByLegacyName(frameName)
			or PromptService.getOfferByKey(mappedName)
		if offer then return offer end
	end

	return nil
end

local function setupBuyButton(buyFrame)
	if not buyFrame or not buyFrame:IsA("Frame") then return end

	local textButton = buyFrame:FindFirstChildOfClass("TextButton") or buyFrame:FindFirstChildOfClass("ImageButton")
	if not textButton then return end

	local uiScale = buyFrame:FindFirstChildOfClass("UIScale") or textButton:FindFirstChildOfClass("UIScale")

	local offer = getOfferForFrame(buyFrame)
	if not offer then
		warn("[ShopSystem] Failed to resolve Catalog offer for " .. buyFrame:GetFullName())
		return
	end

	-- Fetch and update live Robux price dynamically from Roblox MarketplaceService if available
	task.spawn(function()
		local price = PromptService.getOfferRobuxPrice(offer.key)
		if price then
			local costLabel = buyFrame:FindFirstChild("Cost") 
				or buyFrame:FindFirstChild("Price") 
				or (buyFrame.Parent and buyFrame.Parent:FindFirstChild("Cost"))
				or (buyFrame.Parent and buyFrame.Parent:FindFirstChild("Price"))
			
			if costLabel and costLabel:IsA("TextLabel") then
				costLabel.Text = string.format("%d R$", price)
			end
		end
	end)

	ButtonFunctionality.SetupButton(textButton, uiScale, {
		playHoverSound = true,
		playClickSound = true,
		onClickCallback = function()
			print(string.format("[ShopSystem] Buy button clicked for offer '%s'", offer.key))
			PromptService.promptByOfferKey(offer.key)
		end
	})
end

local function findAndSetupBuyButtons(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == "Buy" and child:IsA("Frame") then
			setupBuyButton(child)
		end
		if child:IsA("GuiObject") or child:IsA("Folder") then
			findAndSetupBuyButtons(child)
		end
	end
end

local function initializeShop(shopFrame)
	if not shopFrame then return end

	local scrollingFrame = shopFrame:FindFirstChild("ScrollingFrame", true)
	if not scrollingFrame then return end

	findAndSetupBuyButtons(scrollingFrame)

	scrollingFrame.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "Buy" and descendant:IsA("Frame") then
			task.wait(0.1)
			setupBuyButton(descendant)
		end
	end)

	-- Close Button Setup
	local header = shopFrame:FindFirstChild("Header") or shopFrame
	local closeButton = header:FindFirstChild("Close") or header:FindFirstChild("CloseBtn") or shopFrame:FindFirstChild("CloseBtn")
	if closeButton then
		local uiScale = closeButton:FindFirstChildOfClass("UIScale")
		local actualButton = closeButton:IsA("GuiButton") and closeButton or closeButton:FindFirstChildOfClass("GuiButton")
		if actualButton then
			ButtonFunctionality.SetupButton(actualButton, uiScale, {
				playHoverSound = true,
				playClickSound = true,
				onClickCallback = function()
					OpenFrame.CloseAll()
				end
			})
		end
	end
end

local function startShopSystem()
	local tabsFolder = playerGui:WaitForChild("Tabs", 10)
	if tabsFolder then
		local shopFrame = tabsFolder:WaitForChild("Shop", 10)
		if shopFrame then
			initializeShop(shopFrame)
		end
	end
end


task.spawn(startShopSystem)
