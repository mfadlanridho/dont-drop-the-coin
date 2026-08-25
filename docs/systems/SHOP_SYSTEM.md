# 🛍️ SHOP & MONETIZATION SYSTEM TECHNICAL MANUAL

This document provides a technical guide for managing, editing, adding, and testing Shop items and Robux purchases in **Don't Drop The Coin!**.

---

## 🏗️ 1. SYSTEM ARCHITECTURE OVERVIEW

The Shop System uses an **automated card discovery pattern**. Client scripts scan `StarterGui.Tabs.Shop.ScrollingFrame` for item cards containing a `Buy` frame, resolving product offer keys and Marketplace IDs automatically without manual button scripting.

```
Shop Cards in Studio (Buy.Product StringValue = "Super Glue")
        │
        ▼
ShopSystem.client.luau  ──► Scans ScrollingFrame for frames named "Buy"
        │
        ▼
PromptService.luau      ──► Looks up offer in CatalogIndex & fetches live Robux price
        │
        ▼
MarketplaceService      ──► Prompts Game Pass / Developer Product purchase window
```

---

## 🎨 2. SHOP CARD UI HIERARCHY REQUIREMENT

Every shop item card inside `StarterGui.Tabs.Shop.ScrollingFrame` must conform to the following instance hierarchy:

```
[ItemCardName] (Frame)
├── CardBanner (ImageLabel)          -- Product visual banner graphic
├── Title (TextLabel)                -- Item Title (e.g. "Super Glue")
├── Subtitle (TextLabel)             -- Subtitle / Discount Badge (e.g. "MOST POPULAR 🔥")
├── DescriptionLabel (TextLabel)     -- Feature description text
└── Buy (Frame)                      -- Interactive purchase container
    ├── TextButton (TextButton)      -- Click trigger bound to ButtonFunctionality
    ├── Cost (TextLabel)             -- Price label (dynamically updated to e.g. "399 R$")
    ├── Product (StringValue)        -- Value MUST match the offer key in CatalogIndex.luau
    └── UIScale (UIScale)            -- Button hover/click scale animation object
```

---

## 📋 3. HOW TO ADD A NEW SHOP ITEM (STEP-BY-STEP)

### Step 1: Duplicate a Card in Roblox Studio
1. Open `StarterGui.Tabs.Shop.ScrollingFrame` in Roblox Studio.
2. Duplicate an existing item card (e.g. `SuperGlueCard`).
3. Rename the card (e.g. `VIPPassCard`).
4. Update the `Product` (`StringValue`) inside `card.Buy.Product` to your new offer key (e.g. `Product.Value = "VIP Pass"`).

---

### Step 2: Create the Product on Roblox (via Open Cloud CLI)
Open your terminal in the project root:

```bash
# For a Game Pass:
node tools/monetization/create_gamepass.js "VIP Pass" 499 "Grants VIP chat tag and 2x coin multiplier"

# For a Developer Product:
node tools/monetization/create_product.js "Super Booster" 99 "Instantly boosts speed for 10 minutes"
```
*(Copy the generated Product ID or GamePass ID returned in the console).*

---

### Step 3: Register the Item in `CatalogIndex.luau`
Open `src/shared/Monetization/CatalogIndex.luau` and add your new item entry:

```lua
["VIP Pass"] = {
    key = "VIP Pass",
    kind = "gamePass",              -- "gamePass" or "developerProduct"
    productId = 123456789,           -- Paste generated Roblox Asset ID here
    displayName = "VIP Pass",
    legacyNames = { "VIPPassCard" },
},
```

---

## ⚡ 4. RUNTIME MODULES REFERENCE

### 📖 `CatalogIndex.luau`
*Location: `src/shared/Monetization/CatalogIndex.luau`*
- Maps offer keys, legacy card names, and Roblox Asset IDs.
- Provides lookup functions: `getOfferByKey(key)`, `getOfferByProductId(id)`, `getOfferByLegacyName(name)`.

### 🛒 `PromptService.luau`
*Location: `src/client/Monetization/PromptService.luau`*
- **`PromptService.getOfferRobuxPrice(offerKey)`**: Calls `MarketplaceService:GetProductInfo()` to fetch the real live Robux price directly from Roblox servers.
- **`PromptService.promptByOfferKey(offerKey)`**: Prompts `MarketplaceService:PromptGamePassPurchase()` or `MarketplaceService:PromptProductPurchase()`.

### 🔘 `ShopSystem.client.luau`
*Location: `src/client/Shop/ShopSystem.client.luau`*
- Scans `Shop.ScrollingFrame` for all `Buy` frames on startup.
- Connects `ButtonFunctionality.SetupButton()` to every `Buy.TextButton` (enabling 1.03x hover scale, 0.97x click compression, SFX, and debouncing).
- Dynamically populates `Buy.Cost.Text` with live Roblox pricing.
- Listens to `ScrollingFrame.ChildAdded` to auto-bind dynamically spawned cards.

---

## 🧪 5. TESTING IN ROBLOX STUDIO

1. Open Roblox Studio and start a **Play Test**.
2. Open the Shop by clicking `SHOP 🛒` on the HUD toggle bar.
3. Click any `BUY` button:
   - In Studio test mode, Roblox's native purchase overlay will pop up with a test purchase confirmation.
   - Prices will automatically sync from Roblox Marketplace if valid IDs are configured in `CatalogIndex.luau`.
