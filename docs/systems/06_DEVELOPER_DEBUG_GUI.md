# DeveloperDebugGUI Architecture & Developer Guide

## Overview

`DeveloperDebugGUI` is a modular, high-performance debug interface for Roblox development. It allows developers to register debug panels and real-time controls for game systems without modifying core UI assets or re-implementing diagnostic boilerplate.

---

## File Structure

The system is located under `src/client/Debug/` (which Rojo syncs to `StarterPlayerScripts.Client.Debug`):

```
src/client/Debug/
├── DebugGuiView.luau             # Procedural UI rendering & reconciliation engine
├── DebugGuiController.luau       # Central state manager, API, and render pipeline
└── DebugGuiBootstrap.client.luau # Telemetry startup script (Session & Character stats)
```

---

## Core System Architecture

```
                       ┌──────────────────────────────┐
                       │  DebugGuiBootstrap.client   │
                       │ (Periodically updates stats) │
                       └──────────────┬───────────────┘
                                      │
                                      ▼
┌─────────────────────────┐  setValue/setToggle  ┌─────────────────────────┐
│ Feature LocalScripts    │─────────────────────>│ DebugGuiController      │
│ (e.g. CoinDebugPanel)   │  register controls   │ (State & Throttling)    │
└─────────────────────────┘                      └────────────┬────────────┘
                                                              │ Heartbeat (10 FPS)
                                                              ▼
                                                 ┌─────────────────────────┐
                                                 │ DebugGuiView            │
                                                 │ (Reconciliation Render) │
                                                 └─────────────────────────┘
```

### 1. `DebugGuiView.luau` (Procedural UI Engine)
- **Zero Asset Dependency**: Dynamically constructs the entire GUI (`ScreenGui`, `ScrollingFrame`, `TextButton`, `TextBox`) programmatically.
- **In-Place Reconciliation**: Prevents UI flicker and frame drops. When redrawn, existing UI frames are updated in-place rather than destroyed and recreated.

### 2. `DebugGuiController.luau` (Controller & API)
- **Security Check**: Active by default in **Roblox Studio** (`RunService:IsStudio()`) or for explicitly whitelisted User IDs (`ALLOWED_USER_IDS`). Safe for production environments.
- **Hotkey**: Toggles panel visibility when pressing **P** (`Enum.KeyCode.P`).
- **Throttling**: Renders on `Heartbeat` with a minimum 0.1s interval (capped at 10 FPS) to maintain high game performance.

### 3. `DebugGuiBootstrap.client.luau` (System Telemetry)
- Runs automatically when the player joins.
- Updates baseline statistics every 0.2s:
  - **Session Tab**: Studio Status, Player Name, User ID, Place ID, Job ID, FPS counter.
  - **Player State Tab**: FSM State (`Normal`, `Dashing`, `Ragdolled`, `SafeZone`), Humanoid Physics State, `CanDash`, `CanBeBumped`.
  - **Character Tab**: Character Loaded, Root Position, MoveDirection, Move Magnitude, Floor Material.

### 4. Network Replicated `PlayerFSM` Integration
- **Server Replication**: `PlayerFSM.SetState(player, stateName)` updates the internal state machine on the server and sets `player:SetAttribute("FSMState", stateName)`.
- **Client Sync**: `PlayerFSM.GetState(player)` reads `player:GetAttribute("FSMState")`, and listens to `GetAttributeChangedSignal("FSMState")` to synchronize the client's local state machine in real time.
- **Decoupled Input Architecture**: `InputController.luau` purely handles user input and fires remote events. State transitions (`Normal` $\rightarrow$ `Dashing` $\rightarrow$ `Normal`) are managed authoritatively by `CombatServer.luau` and replicated automatically to all clients.

---

## Developer API Guide

Any client module or `LocalScript` can register debug panels and rows using `DebugGuiController`.

### Importing the Controller
```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugGuiController = require(game:GetService("Players").LocalPlayer
	.PlayerGui
	:WaitForChild("StarterPlayerScripts") -- or relative path script.Parent:WaitForChild("DebugGuiController")
)
```

### 1. Read-Only Label (`setValue`)
Displays a formatted key-value string.
```luau
DebugGuiController.setValue(
	"coins",           -- Panel Key
	"stackCount",      -- Row Key
	"15 Coins",        -- Value (string/number/boolean)
	"Coin System",     -- Panel Display Name
	10,                -- Panel Order
	"Current Stack",   -- Row Display Name
	1                  -- Row Order
)
```

### 2. Interactive Toggle Switch (`setToggleRow`)
Creates an ON/OFF button. The callback receives a boolean value when clicked.
```luau
local godModeEnabled = false

DebugGuiController.setToggleRow(
	"combat",
	"godMode",
	"Enable God Mode",
	godModeEnabled,
	function(newValue: boolean)
		godModeEnabled = newValue
		print("God mode set to:", godModeEnabled)
	end,
	"Combat", -- Panel Name
	20,       -- Panel Order
	1         -- Row Order
)
```

### 3. Text Input Box (`setInputRow`)
Creates an editable input field. The callback triggers when the user presses **Enter**.
```luau
DebugGuiController.setInputRow(
	"movement",
	"walkSpeed",
	"Walk Speed Override",
	"16",
	function(inputText: string)
		local speed = tonumber(inputText)
		if speed then
			local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = speed
			end
		end
	end,
	"Movement", -- Panel Name
	30,          -- Panel Order
	1            -- Row Order
)
```

### 4. Action Button (`setButtonRow`)
Creates a button that executes an action when clicked.
```luau
DebugGuiController.setButtonRow(
	"coins",
	"dropStack",
	"Clear Coin Stack",
	"DROP", -- Button label
	function()
		print("Stack dropped via debug panel!")
	end,
	"Coin System", -- Panel Name
	10,            -- Panel Order
	2              -- Row Order
)
```

### Removing Rows or Panels
```luau
-- Remove a specific row
DebugGuiController.removeValue("coins", "stackCount")

-- Remove an entire panel
DebugGuiController.removePanel("coins")
```

---

## Controls Summary

| Action | Control |
| :--- | :--- |
| **Toggle Visibility** | Press `P` key |
| **Switch Tabs** | Click tab buttons at the top of the panel |
| **Submit Input Value** | Type into text box and press `Enter` |
| **Toggle Switch** | Click `ON` / `OFF` button |
