# Logger System Architecture & Technical Documentation

The **Logger** utility is a centralized, category-driven debug logging system designed for both client and server code in Roblox. Located at [`src/shared/Utils/Logger.luau`](../../src/shared/Utils/Logger.luau) (replicated as `ReplicatedStorage.Shared.Utils.Logger`), it provides fine-grained control over console logging by feature category and execution environment (Studio vs. Live Game).

---

## 1. Core Architecture & Features

### Environment Awareness (`RunService:IsStudio()`)
The Logger evaluates `RunService:IsStudio()` at module initialization. Category flags can leverage this condition to ensure debug logs appear while testing in Roblox Studio but are silently muted in production/live servers to reduce console clutter and overhead.

### Category-Based Toggles (`Logger.Categories`)
Categories represent game systems or feature domains (e.g., `Combat`, `Input`, `DataStore`, `Ragdoll`).
Log outputs for any category can be configured using three toggle patterns:

| Configuration Pattern | Studio Behavior | Live Game Behavior | Usage Case |
| :--- | :--- | :--- | :--- |
| `IS_STUDIO and true` | ✅ **Enabled** | ❌ **Disabled** | Verbose debugging for local development. |
| `true` | ✅ **Enabled** | ✅ **Enabled** | Critical runtime diagnostics required in production. |
| `false` | ❌ **Disabled** | ❌ **Disabled** | Muted logs across all environments. |

---

## 2. API Reference

### `Logger.Categories`
> **Type**: `{ [string]: boolean }`

A key-value map defining active log categories.

```lua
Logger.Categories = {
    Combat        = IS_STUDIO and true,
    Input         = IS_STUDIO and true,
    Ragdoll       = IS_STUDIO and true,
    DataStore     = IS_STUDIO and true,
    CoinSpawner   = IS_STUDIO and true,
    FSM           = IS_STUDIO and true,
    DebugGui      = IS_STUDIO and true,
    Shop          = IS_STUDIO and true,
    LootExplosion = IS_STUDIO and true,
}
```

---

### `Logger.log(category: string, ...: any)`
> **Description**: Evaluates if the given category is enabled (`true`). If enabled, prints `[category]` prefixed to the variadic arguments in the output console.

```lua
Logger.log("Combat", "Player attacked victim", targetPlayer)
-- Console Output: [Combat] Player attacked victim VictimName
```

---

### `Logger.create(category: string): (...any) -> ()`
> **Description**: Factory method returning a scoped logging function bound to a specific category. Ideal for module headers to avoid specifying the category string on every log call.

```lua
local debugLog = Logger.create("Input")

debugLog("Keybind E pressed!")
-- Console Output: [Input] Keybind E pressed!
```

---

## 3. Integration Guide

To integrate Logger into any client or server script:

### Step 1: Require the Shared Logger Module
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger"))
```

### Step 2: Create a Scoped Logger Function
```lua
local debugLog = Logger.create("YourCategoryName")
```

### Step 3: Replace Standard `print` Calls
```lua
-- Before:
print(string.format("[YourCategoryName] Action triggered for %s", player.Name))

-- After:
debugLog(string.format("Action triggered for %s", player.Name))
```

---

## 4. Best Practices & Guidelines

1. **Use `Logger.create` at Module Scope**: Always bind `debugLog` at the top of your file to maintain clean, readable function bodies.
2. **Add New Categories to `Logger.Categories`**: When introducing a new subsystem, register its category name in `Logger.Categories` with `IS_STUDIO and true`.
3. **Use Format Strings for Complex Data**: Combine `string.format()` or string interpolation with `debugLog()` for structured log outputs.
