# Roblox Monetization Management Tools

This directory contains Open Cloud API scripts for managing Developer Products and Game Passes for **Don't Drop the Coin**.

## Setup

Ensure your `.env` file at the root of the project contains:

```env
ROBLOX_OPEN_CLOUD_KEY=your_api_key_here
ROBLOX_UNIVERSE_ID=your_universe_id_here
```

Install dependencies if not already done:

```bash
npm install
```

---

## Usage

### 📦 Developer Products

- **List Products**:
  ```bash
  npm run products:list
  # or: node tools/monetization/list_products.js
  ```

- **Create Product**:
  ```bash
  node tools/monetization/create_product.js "100 Coins" 49 "Instantly grants 100 Coins"
  ```

- **Update Product**:
  ```bash
  node tools/monetization/update_product.js <productId> --price=99 --name="200 Coins"
  ```

---

## 🎟️ Game Passes

- **List Game Passes**:
  ```bash
  npm run gamepasses:list
  # or: node tools/monetization/list_gamepasses.js
  ```

- **Create Game Pass**:
  ```bash
  node tools/monetization/create_gamepass.js "VIP Pass" 299 "Unlocks VIP multiplier"
  ```

- **Update Game Pass**:
  ```bash
  node tools/monetization/update_gamepass.js <gamePassId> --price=399 --sale=true
  ```
