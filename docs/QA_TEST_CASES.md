# 🧪 MASTER QA TEST SUITE & COMPREHENSIVE TEST CASES

This document provides step-by-step QA test procedures and expected results for verifying all game systems in **Don't Drop The Coin!**.

---

## 📋 SUMMARY OF QA TEST SUITES

| Test Suite | Component | Key Feature | Target Result |
| --- | --- | --- | --- |
| **TS-01** | DataStore & Session Locking | ProfileStore Persistence | Saved coins reload on rejoin; session locking prevents dupe bugs |
| **TS-02** | Coin Spawning & Head Stacking | 3D Coin Stack Welding | Coins stack sequentially on Head; caps visual parts at 30 |
| **TS-03** | Dash Bump Combat & Hitboxes | `Workspace:Spherecast` & HitboxCapsules | Continuous 0.3s hitbox sweep strikes target `HitboxCapsules` 100% reliably |
| **TS-04** | 3D Ragdoll & Loot Explosion | BallSocket Constraints & Radial Scatter | Character pitches/rolls 3D on floor for 2.5s; head stack scatters in 360° arc |
| **TS-05** | Bank Vaults & Multipliers | Multi-Vault Cashouts & SafeZone State | Stepping on vaults applies multipliers (`1x`, `1.2x`, `2x`, `3x`) & blocks PvP attacks |
| **TS-06** | Developer Debug GUI & Gizmos | `P` Key Debug Panel | Toggling `Always Show Hitboxes` renders real-time 3D green wireframe boxes |
| **TS-07** | Target Dummy Spawner | 1-Player Solo Testing | 3 permanent arena dummies spawn and auto-respawn 3s after void fall |

---

## 🏦 BANK VAULT QA TESTING WALKTHROUGH

### 1. Spawn with 3 Starting Coins
1. Hit **Play (`F5`)** in Studio.
2. Look at top right player list: `leaderstats.Coins: 0` and `leaderstats.Stack: 3`.

### 2. Test `LobbyVault` (1x Multiplier — Green Pad)
1. Walk forward to the **Neon Green Pad** at `(0, 0.5, -45)`.
2. Step onto the pad:
   * Your 3 head stack coins cash out!
   * `leaderstats.Stack` resets to **`0`**.
   * `leaderstats.Coins` increases from `0` to **`3`** ($3 \text{ coins} \times 1 = \$3$).
   * Console log: `[Combat] Player NotoriousGamedev BANKED 3 coins for $3 cash at LobbyVault!`.

### 3. Test `GroupMemberVault` (1.2x Multiplier — Gold Pad)
1. Pick up a new coin or press **`P`** $\rightarrow$ **`Combat Debug`** to get coins.
2. Walk to the **Neon Gold Pad** at `(-30, 0.5, -45)`.
3. Step onto the pad:
   * Cash out with a **+20% Group Bonus**!
   * `leaderstats.Coins` increases by **`4`** ($3 \text{ coins} \times 1.2 = 3.6 \rightarrow \$4$).
   * Console log: `[Combat] Player NotoriousGamedev BANKED 3 coins for $4 cash at GroupMemberVault! (Multiplier: 1.2x)`.

### 4. Test Sky Vaults (2x & 3x Multipliers)
1. Walk/teleport to **`Zone2ChaosVault`** (Cyan Pad at Y=60) or **`Zone3VoidVault`** (Magenta Pad at Y=150):
   * `Zone2ChaosVault` **doubles** your cashout ($3 \text{ coins} \times 2 = \$6$).
   * `Zone3VoidVault` **triples** your cashout ($3 \text{ coins} \times 3 = \$9$).

### 5. Test Safe Zone Combat Immunity
1. Stand on top of any Vault Pad.
2. Notice your state becomes **`SafeZone`**:
   * Opponents cannot bump or knock you back while standing on the vault pad!

---

## 🧪 DETAILED TEST CASES

### 🟦 TS-01: DataStore & ProfileStore Persistence
* **TC-01.1 (Data Load):** Join game in Studio. Verify `leaderstats.Coins` matches ProfileStore balance.
* **TC-01.2 (Data Save):** Cash out coins at Bank Vault Pad. Stop Play mode. Re-run Play mode $\rightarrow$ verify banked coins persist.

### 🟩 TS-02: Coin Spawning & Head Stacking
* **TC-02.1 (Coin Collection):** Walk over a floating coin node in Zone 1. Verify coin snaps to `Character.Head` socket and node respawns after 3 seconds.
* **TC-02.2 (Render Cap):** Collect > 30 coins. Verify physical part rendering caps at 30 mesh parts and floating text displays numerical count.

### 🟥 TS-03: Dash Bump Combat & Hitbox Engine
* **TC-03.1 (Dash Bump Execution):** Press **`E`** (PC) or touch screen button (Mobile). Verify character lunges forward 15 studs over 0.3s and 5.0s cooldown begins.
* **TC-03.2 (Hitbox Intersection):** Dash into a target dummy or opponent. Verify continuous 0.3s Heartbeat `Spherecast` detects target's `HitboxCapsule` and triggers knockback launch.

### 🟨 TS-04: 3D Tumbling Ragdoll & Loot Explosion
* **TC-04.1 (Joint Disassembly):** Trigger ragdoll on player or dummy. Verify `Motor6D` joints disable, `BallSocketConstraints` activate, and character tumbles on floor.
* **TC-04.2 (Upright Disable):** Verify `Humanoid.EvaluateStateMachine = false` and `PlatformStand = true` prevent character from popping upright during 2.5s ragdoll.
* **TC-04.3 (Loot Scatter):** Verify head stack detaches immediately and physical coins scatter in a 360° arc with 10s vacuum collection window.

### 🟪 TS-05: Multi-Vault Cashouts & Safe Zone Immunity
* **TC-05.1 (Lobby Vault 1x):** Step onto `LobbyVault` (`0, 0.5, -45`). Verify stack clears, `leaderstats.Coins` increases by stack count $\times 1$, and `BankCoins` remote fires.
* **TC-05.2 (Group Member Vault 1.2x):** Step onto `GroupMemberVault` (`-30, 0.5, -45`). Verify 1.2x cash multiplier bonus is applied.
* **TC-05.3 (Zone 2 & 3 Vaults):** Step onto `Zone2ChaosVault` (Y=60) or `Zone3VoidVault` (Y=150). Verify `2x` or `3x` multiplier multiplies stack cashout.
* **TC-05.4 (SafeZone Immunity):** Stand on any vault pad. Verify `PlayerFSM.GetState(player)` is `"SafeZone"` and opponents cannot attack or bump player.

### 🟧 TS-06: Developer Debug GUI & Gizmos
* **TC-06.1 (Debug Panel Toggle):** Press **`P`** in game. Verify Developer Debug GUI opens with `Combat Debug` tab.
* **TC-06.2 (Always-On Hitboxes):** Toggle `Always Show Hitboxes` to ON. Verify green 3D wireframe boxes (`BoxHandleAdornment`) outline all target `HitboxCapsules` in real-time.
* **TC-06.3 (Debug Action Buttons):** Click `SPAWN TEST DUMMY` or `BANK CURRENT STACK`. Verify actions execute instantly.

---

## 🕹️ HOW TO RUN MANUAL QA IN STUDIO

1. Hit **Play (`F5`)** in Roblox Studio.
2. Verify `leaderstats` displays `Coins: 0` and `Stack: 3`.
3. Walk to the 4 Bank Vaults in Workspace (`LobbyVault`, `GroupMemberVault`, `Zone2Vault`, `Zone3Vault`) to test cashouts.
4. Press **`P`** to open Debug Panel $\rightarrow$ toggle `Always Show Hitboxes` $\rightarrow$ press **`E`** to test Dash Bump into the 3 arena target dummies!
