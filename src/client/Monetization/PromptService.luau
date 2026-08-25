-- PromptService Module
-- Fetches live Robux prices and prompts Roblox MarketplaceService purchase windows
-- Place in: src/client/Monetization/PromptService.luau -> StarterPlayer.StarterPlayerScripts.Client.Monetization.PromptService

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local MonetizationFolder = SharedFolder:WaitForChild("Monetization")
local CatalogIndex = require(MonetizationFolder:WaitForChild("CatalogIndex"))

local productPriceCache = {}

local PromptService = {}

function PromptService.getOfferRobuxPrice(offerKey)
	if type(offerKey) ~= "string" or offerKey == "" then
		return nil
	end

	local cachedPrice = productPriceCache[offerKey]
	if cachedPrice ~= nil then
		return cachedPrice
	end

	local offer = PromptService.getOfferByKey(offerKey)
	if offer == nil then
		return nil
	end

	if not offer.productId or offer.productId <= 0 then
		return nil
	end

	local infoType
	if offer.kind == "developerProduct" then
		infoType = Enum.InfoType.Product
	elseif offer.kind == "gamePass" then
		infoType = Enum.InfoType.GamePass
	else
		return nil
	end

	local ok, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(offer.productId, infoType)
	end)
	if not ok or type(productInfo) ~= "table" then
		warn(string.format(
			"[Monetization][PromptService] Failed to fetch product info for offer %s: %s",
			tostring(offerKey),
			tostring(productInfo)
		))
		return nil
	end

	local priceInRobux = productInfo.PriceInRobux
	if type(priceInRobux) == "number" then
		productPriceCache[offerKey] = priceInRobux
		return priceInRobux
	end

	return nil
end

local function promptOffer(offer)
	if offer == nil then
		return false
	end

	if not offer.productId or offer.productId <= 0 then
		warn(string.format("[Monetization][PromptService] Cannot prompt purchase for '%s' - Product ID not set yet", tostring(offer.key)))
		return false
	end

	if offer.kind == "gamePass" then
		MarketplaceService:PromptGamePassPurchase(localPlayer, offer.productId)
		return true
	end

	if offer.kind == "developerProduct" then
		MarketplaceService:PromptProductPurchase(localPlayer, offer.productId)
		return true
	end

	warn(string.format(
		"[Monetization][PromptService] Unsupported offer kind %s for offer %s",
		tostring(offer.kind),
		tostring(offer.key)
	))
	return false
end

function PromptService.getOfferByKey(offerKey)
	return CatalogIndex.getOfferByKey(offerKey)
end

function PromptService.getOfferByProductId(productId)
	return CatalogIndex.getOfferByProductId(productId)
end

function PromptService.getOfferByLegacyName(legacyName)
	return CatalogIndex.getOfferByLegacyName(legacyName)
end

function PromptService.promptByOfferKey(offerKey)
	local offer = PromptService.getOfferByKey(offerKey)
	if offer == nil then
		warn(string.format("[Monetization][PromptService] Unknown offer key %s", tostring(offerKey)))
		return false
	end

	return promptOffer(offer)
end

function PromptService.promptByProductId(productId)
	local offer = PromptService.getOfferByProductId(productId)
	if offer == nil then
		warn(string.format("[Monetization][PromptService] Unknown product id %s", tostring(productId)))
		return false
	end

	return promptOffer(offer)
end

function PromptService.promptByLegacyName(legacyName)
	local offer = PromptService.getOfferByLegacyName(legacyName)
	if offer == nil then
		warn(string.format("[Monetization][PromptService] Unknown legacy product name %s", tostring(legacyName)))
		return false
	end

	return promptOffer(offer)
end

return table.freeze(PromptService)
