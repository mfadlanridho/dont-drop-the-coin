# DataStore Architecture Comparison: Custom DataStoreManager vs. ProfileStore

This document provides a technical comparison between the custom implementation in `src/server/Services/DataStoreManager.luau` and the battle-tested community standard **ProfileStore** (by loleris).

---

## 1. Executive Summary

| Attribute | Custom `DataStoreManager.luau` | `ProfileStore` (by loleris) |
| :--- | :--- | :--- |
| **Primary Advantage** | Zero external dependencies, clean readable codebase (~550 LOC), easily mockable. | Battle-tested at scale, highly resilient against Roblox cloud outages, dupe-proof. |
| **Primary Risk** | Subtle race conditions (dirty flag overwrite during saves), 3-minute hard lockout on server crashes, no budget queue. | Heavy library abstraction, requires dependency management (`ServerPackages` / Wally). |
| **Best Used For** | Prototyping, small-scale testing, local offline development. | **Production live releases with real players and monetization.** |

---

## 2. Architectural Comparison

### Custom `DataStoreManager.luau`
The custom implementation interacts directly with Roblox's native `DataStoreService:GetDataStore("PlayerData_V2")`.
* **Session Locking**: Implemented manually via `UpdateAsync`. When a server loads a player, it writes a lock string composed of `JobId` and `os.time()` into `__SessionLock` and `__SessionTime`.
* **Reconciliation**: A custom `reconcile` recursive table copy that merges default values into loaded player tables.
* **Autosave**: A background `task.spawn` loop that runs every 60 seconds (`AUTOSAVE_INTERVAL = 60`) checking for dirty sessions and triggering non-blocking `saveSession` calls.
* **Shutdown**: A `game:BindToClose` loop that saves all active sessions and polls up to 25 seconds for in-flight saves to complete.

### ProfileStore (ProfileService)
ProfileStore wraps Roblox's `DataStoreService` in an event-driven session lease management engine.
* **Active Session Leases**: Continuously renews active session locks on a heartbeat interval rather than relying on a static timeout.
* **Smart Session Stealing**: Allows incoming servers to request and negotiate lock transfers from old servers.
* **Request Throttling Queue**: Internally queues and batches calls to comply with Roblox DataStore rate limits (`60 + numPlayers * 10` per minute).
* **Global Updates**: Built-in messaging pipeline allowing purchases, moderator actions, or gifting to offline players.

---

## 3. Side-by-Side Feature Matrix

| Feature | Custom `DataStoreManager.luau` | `ProfileStore` | Technical Assessment |
| :--- | :---: | :---: | :--- |
| **Production Scale Track Record** | ❌ None (New) | ✅ 100M+ Plays | ProfileStore has handled millions of concurrent users across top Roblox games for years. |
| **Session Locking (Dupe Protection)** | ⚠️ Basic (Static Timeout) | ✅ Advanced (Active Heartbeat) | Custom version prevents basic cross-server dupe, but has edge cases. |
| **Crash Recovery Time** | ⚠️ Up to 180 seconds | ✅ Seconds to 1 minute | If a server crashes, custom version locks the player out of all servers for 3 full minutes. |
| **In-Flight Mutation Handling** | ⚠️ Race Condition | ✅ Transaction-Safe | Custom autosave clears the `Dirty` flag after save, potentially dropping coins earned mid-save. |
| **API Rate Limit Handling** | ⚠️ Exponential Backoff only | ✅ Budget Queue Manager | Custom version can exhaust DataStore limits during server spikes or mass retries. |
| **Offline Gifting / Global Updates** | ❌ Not supported | ✅ Built-in | ProfileStore allows modifying data for players who are not currently online. |
| **Code Readability & Simplicity** | ✅ High (~550 LOC) | ⚠️ Low (Complex Metatables) | Custom code is transparent and easy for junior developers to follow. |
| **External Dependencies** | ✅ None | ⚠️ Requires Wally / ServerPackages | Custom code has zero build-time package requirements. |
| **Mockability for Unit Tests** | ✅ Very Easy | ⚠️ Requires MockStore library | Custom version is easily tested via mock player tables as seen in `DataStoreTest.luau`. |

---

## 4. Deep Dive: Edge Cases in the Custom Version

### 1. The "Dirty Flag" Race Condition during Autosave
In `DataStoreManager.luau`:
```luau
-- 1. Snapshot taken:
local dataToSave = deepCopy(session.Data)

-- 2. Network call to Roblox DataStore (takes 0.5s - 2s):
local success, result = executeWithRetries(...)

-- 3. Dirty flag reset AFTER save:
session.Dirty = false
```
* **The Bug**: If a player earns coins through `AddBankedCash` while step 2 is in-flight over the network, `session.Dirty` is set to `true` for the new balance. When step 3 finishes, it unconditionally sets `session.Dirty = false`, wiping out the dirty state for the new coins. If the player leaves immediately after, those new coins will not be saved.
* **Fix**: Use a version number, mutation counter, or timestamp comparison (`LastModifiedAt > LastSavedAt`) instead of a simple boolean.

### 2. The 180-Second Hard Lockout on Crashes
```luau
local SESSION_TIMEOUT = 180 -- 3 minutes
```
* If a Roblox game server crashes (or Roblox terminates an instance abruptly), the `BindToClose` handler may not complete, leaving `__SessionLock` intact.
* When that player tries to join another server, the new server sees `currentTime - existingTime < SESSION_TIMEOUT` and refuses to load data. The player will be repeatedly kicked or blocked for 3 full minutes.
* ProfileStore avoids this by frequently renewing a short lease and implementing an active session takeover protocol.

### 3. DataStore Request Budget Exhaustion
Roblox imposes strict DataStore request budgets per place instance:
$$\text{Budget} = 60 + (\text{Number of Players} \times 10) \text{ requests/min}$$
* If a 30-player server experiences high network latency, the retry loop (`SAVE_RETRIES = 5`) across multiple players can quickly consume the entire budget.
* When the budget hits 0, Roblox drops requests with `Request was throttled, but queued request was dropped`.
* ProfileStore tracks `DataStoreService:GetRequestBudgetForRequestType` and paces its requests accordingly.

---

## 5. Strategic Recommendations

### Phase 1: During Active Prototyping & Development (Current Stage)
* The custom `DataStoreManager.luau` is completely adequate for internal testing, Studio debugging, and quick unit testing.
* It eliminates package sync issues between developers who work in Studio vs. those who use Rojo/Wally.

### Phase 2: Prior to Public Release / Paid Access
* **Strong Recommendation**: Migrate back to **`ProfileStore`** before opening the game to real traffic.
* **Why**: The risk of player data rollbacks, coin duplication exploits, and 3-minute crash lockouts in a live economy is unacceptable for player retention and monetization.
* **Migration Strategy**: The public API functions (`GetData`, `AddBankedCash`, `RemoveCoins`, `LoadPlayer`) can keep their exact function signatures, while the internal storage mechanism is wired back to `ProfileStore`.
