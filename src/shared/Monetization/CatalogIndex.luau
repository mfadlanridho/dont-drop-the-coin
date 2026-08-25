-- CatalogIndex Module
-- Central registry of all monetization offers for Don't Drop The Coin!
-- Place in: src/shared/Monetization/CatalogIndex.luau -> ReplicatedStorage.Shared.Monetization.CatalogIndex

local CatalogIndex = {}

local OFFERS = {
	["Super Glue"] = {
		key = "Super Glue",
		kind = "gamePass",
		productId = 0, -- Replace with actual GamePass ID when generated via Open Cloud
		displayName = "Super Glue",
		legacyNames = { "SuperGlue", "SuperGlueCard" },
	},
	["Mega Dash Range"] = {
		key = "Mega Dash Range",
		kind = "gamePass",
		productId = 0, -- Replace with actual GamePass ID when generated via Open Cloud
		displayName = "Mega Dash Range",
		legacyNames = { "MegaDash", "MegaDashCard" },
	},
	["Instant Bank"] = {
		key = "Instant Bank",
		kind = "developerProduct",
		productId = 0, -- Replace with actual DeveloperProduct ID when generated via Open Cloud
		displayName = "Instant Bank",
		legacyNames = { "InstantBank", "InstantBankCard" },
	},
	["Nuclear Revenge"] = {
		key = "Nuclear Revenge",
		kind = "developerProduct",
		productId = 0, -- Replace with actual DeveloperProduct ID when generated via Open Cloud
		displayName = "Nuclear Revenge",
		legacyNames = { "NuclearRevenge", "NuclearRevengeCard" },
	},
	["Gacha Skin Roll"] = {
		key = "Gacha Skin Roll",
		kind = "developerProduct",
		productId = 0, -- Replace with actual DeveloperProduct ID when generated via Open Cloud
		displayName = "Gacha Skin Roll",
		legacyNames = { "GachaSkinRoll", "GachaSkinRollCard" },
	},
}

function CatalogIndex.getOfferByKey(key)
	if type(key) ~= "string" or key == "" then return nil end
	if OFFERS[key] then return OFFERS[key] end
	for _, offer in pairs(OFFERS) do
		if offer.key == key or offer.displayName == key then
			return offer
		end
	end
	return nil
end

function CatalogIndex.getOfferByProductId(productId)
	if type(productId) ~= "number" or productId <= 0 then return nil end
	for _, offer in pairs(OFFERS) do
		if offer.productId == productId then
			return offer
		end
	end
	return nil
end

function CatalogIndex.getOfferByLegacyName(legacyName)
	if type(legacyName) ~= "string" or legacyName == "" then return nil end
	for _, offer in pairs(OFFERS) do
		if offer.legacyNames then
			for _, alias in ipairs(offer.legacyNames) do
				if alias == legacyName then
					return offer
				end
			end
		end
	end
	return CatalogIndex.getOfferByKey(legacyName)
end

function CatalogIndex.getAllOffers()
	return OFFERS
end

return table.freeze(CatalogIndex)
