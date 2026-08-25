# 📐 DON'T DROP THE COIN! — UI & MONETIZATION ARCHITECTURE

This document provides a comprehensive technical reference for the UI framework, ScreenGui hierarchy, animation system, audio pipeline, and Open Cloud monetization tooling for **Don't Drop The Coin!**.

---

## 🏛️ 1. SCREENGUI HIERARCHY & LAYERING

The project utilizes a **3-Tier ScreenGui Hierarchy** in `StarterGui` to maintain rock-solid layer control, clean modal isolation, and seamless mobile viewport scaling.

```
game.StarterGui
│
├── 1️⃣ HUDGui (ScreenGui) ───────────── DisplayOrder = 1, ResetOnSpawn = false
│   ├── WalletFrame                  -- Top-left/center cash & coin stack count
│   ├── StackMeter                   -- Side vertical stack height & sway stability bar
│   ├── AbilityBar                   -- Touch button / 'E' key Dash Bump with radial cooldown
│   └── LeaderboardFrame             -- Server stack leaderboard
│
├── 2️⃣ Menus & Tabs (ScreenGui) ────── DisplayOrder = 5 (Menus) & 10 (Tabs)
│   ├── Menus.Toggles                -- Container for HUD navigation buttons (Shop, VIP, Settings)
│   └── Tabs                         -- Container for modal popup windows:
│       ├── Black                    -- Fullscreen dark background overlay (Transparency = 0.5)
│       ├── Shop                     -- Shop modal window (Passes, Products, Gacha)
│       ├── Passes                   -- Dedicated Game Pass showcase
│       └── Settings                 -- Audio, graphics, and controls modal
│
└── 3️⃣ OverlayGui (ScreenGui) ───────── DisplayOrder = 100, ResetOnSpawn = false
    ├── RevengePrompt                -- Defeat popup displaying attacker face + "Nuclear Revenge" prompt
    ├── EmergencyBankPrompt          -- High-stack hazard warning (>50 coins) + "Instant Bank" prompt
    └── ToastContainer               -- Top-center floating notifications ("+100 Coins", "Stack Saved!")
```

---

## 🔌 2. SHARED UI MODULES & API REFERENCE

All UI scripts are modularized in `src/shared/UI/` (mapped to `ReplicatedStorage.Shared.UI`).

### 📦 `OpenFrame.luau`
*Location: `src/shared/UI/OpenFrame.luau`*

Central UI state manager for modal tab frames, screen dimming, and HUD isolation.

- **`OpenFrame.ToggleFrame(buttonOrName: Instance | string)`**:
  - Toggles visibility for a target frame inside `PlayerGui.Tabs` or `PlayerGui.Menus.Tabs`.
  - Automatically hides any currently opened modal tab frame.
  - Fades in dark overlay frame (`Tabs.Black`) and enables `Lighting.Blur`.
  - Hides non-essential HUD elements during menu viewing.
- **`OpenFrame.CloseAll()`**:
  - Closes all active modal windows, fades out the black background, disables `Lighting.Blur`, and restores HUD visibility.
- **Character Respawn Reset**:
  - Automatically connects to `Humanoid.Died` and `Player.CharacterAdded` to force-reset UI state on death.

---

### ✨ `UIEffects.luau`
*Location: `src/shared/UI/UIEffects.luau`*

Handles pop-out animations, background depth-of-field blur, and audio cues.

- **`UIEffects.open(frame: GuiObject, options: table?)`**:
  - Sets `frame.Visible = true`.
  - Tweens `UIScale.Scale` from `0` $\rightarrow$ `TargetScale` using `Back/Out` easing over **0.3 seconds**.
  - Plays `Open_UI` sound effect.
- **`UIEffects.close(frame: GuiObject, options: table?)`**:
  - Tweens `UIScale.Scale` from `TargetScale` $\rightarrow$ `0` using `Back/In` easing over **0.2 seconds**.
  - Hides `frame.Visible = false` upon tween completion.
  - Plays `UI_Close` sound effect.
- **Race Condition Counter (`closeGeneration`)**:
  - Assigns a generation ID to each close request so rapid toggle button spamming won't trigger stale `task.delay` callbacks.

---

### 🔘 `ButtonFunctionality.luau`
*Location: `src/shared/UI/ButtonFunctionality.luau`*

Universal micro-interaction binder for `GuiButton` and `GuiObject` instances.

- **Hover Animation**: Tweens `UIScale.Scale` to `1.03x` on `MouseEnter` or Gamepad `SelectionGained`. Plays `Hover` SFX.
- **Click Compression**: Tweens `UIScale.Scale` to `0.97x` on `InputBegan` (Mouse, Touch, Gamepad). Plays `Click` SFX.
- **Debounced Callback**: Enforces a `0.25s` click threshold to prevent rapid-fire double clicks.
- **API**: `ButtonFunctionality.SetupButton(button, uiScale, { onClickCallback = function() ... end })`.

---

### 🗂️ `SubTabManager.luau`
*Location: `src/shared/UI/SubTabManager.luau`*

Manages sub-category tabs *inside* modal windows (e.g. switching between *Game Passes* and *Products* inside `Shop`).

```lua
local SubTabManager = require(ReplicatedStorage.Shared.UI.SubTabManager)

local shopSubTabs = SubTabManager.new({
    buttonsFolder = shopFrame.TabButtons,
    contentFolder = shopFrame.TabContents,
    defaultTab = "GamePasses",
    activeColor = Color3.fromRGB(255, 220, 0),
    inactiveColor = Color3.fromRGB(180, 180, 180),
})
```

---

### 📱 `MenuToggleController.client.luau`
*Location: `src/client/Controllers/MenuToggleController.client.luau`*

Client controller that automatically binds HUD toggle buttons to `OpenFrame.ToggleFrame()`.

- **Mobile Viewport Auto-Scaling**: Monitors `UserInputService.TouchEnabled` and `AbsoluteSize` to automatically scale HUD toggle buttons up to **1.5x scale** on mobile touch screens for easy tapping.

---

## 💸 3. MONETIZATION MATRIX & OPEN CLOUD TOOLS

Monetization targets high emotional triggers (**Fear, Panic, Rage, Vanity**).

### 🏷️ Product Catalog & Pricing Matrix

| Item | Type | Price | Location / Trigger | Game Effect |
| :--- | :--- | :--- | :--- | :--- |
| **Super Glue Passive** | Game Pass | 399 Robux | Shop Modal | Permanently retains **50% of coin stack** upon ragdoll wipeout. |
| **Mega Dash Range** | Game Pass | 249 Robux | Shop Modal | Increases Dash Bump hitbox radius by **+100%**. |
| **Nuclear Revenge** | Dev Product | 29 Robux | Defeat Pop-up | Lightning strike VFX that ragdolls and explodes attacker's stack. |
| **Instant Bank** | Dev Product | 39 Robux | Stack > 50 Prompt | Teleports player & entire stack safely to Bank Zone. |
| **Gacha Skin Roll** | Dev Product | 49 Robux | Lobby Gacha Prop | Rolls for cosmetic stack skins & ultra-rare stat boosts (+25% Speed). |

---

### 🛠️ Roblox Open Cloud Management Scripts

Managed in **[`tools/monetization/`](file:///Users/ridhomfadlan/Documents/Roblox%20Files/dont-drop-the-coin/tools/monetization/)**:

```bash
# Developer Products
npm run products:list
node tools/monetization/create_product.js "Nuclear Revenge" 29 "Strike back at attacker"
node tools/monetization/update_product.js <productId> --price=39

# Game Passes
npm run gamepasses:list
node tools/monetization/create_gamepass.js "Super Glue" 399 "Retain 50% stack on ragdoll"
node tools/monetization/update_gamepass.js <gamePassId> --price=499
```

Environment config required in `.env`:
```env
ROBLOX_OPEN_CLOUD_KEY=your_api_key_here
ROBLOX_UNIVERSE_ID=your_universe_id_here
```

---

## 🔊 4. AUDIO ASSET PIPELINE

Sound assets live in `ReplicatedStorage`:

```
game.ReplicatedStorage
└── Sounds / Shared.Sounds
    └── GuisSounds
        ├── Hover (Sound)     -- Button hover SFX
        ├── Click (Sound)     -- Button press SFX
        ├── Open_UI (Sound)   -- Modal open SFX
        └── UI_Close (Sound)  -- Modal close SFX
```

All UI modules check for these sounds safely; if missing, UI actions function normally without erroring.
