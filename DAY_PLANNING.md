# 📅 DON'T DROP THE COIN! — SCRIPTER'S 7-DAY MVP PRODUCTION PLAN

**Role:** Lead Scripter  
**Objective:** Program, network, and optimize all game systems for a 7-day MVP launch.  
**Target Platform:** Roblox (Mobile / PC / Console)  

---

## 💡 SCHEDULE FOUNDATION & RATIONALE

This 7-day schedule is structured based on a **Dependency-First Engineering Approach**:

1. **System Dependencies (Data & State First):** You cannot store coins before having a DataStore; you cannot bank coins before collecting them; you cannot explode stacks before building the stacking engine.
2. **Risk-First Prototyping:** High-risk custom mechanics (custom head wobble physics & physics ragdoll transitions) are tackled in **Days 2 & 3** so any physics edge cases (stack clipping, networking lag) are resolved early.
3. **Juiciness Layering:** Audio, VFX, and UI animations are integrated *after* core mechanics are solid (Day 5), ensuring no time is wasted polishing broken scripts.
4. **Monetization & Retention Hooks:** Gamepasses, Developer Products, and Group APIs rely on completed core loops and are added on Day 6.

---

## 🎯 WEEK AT A GLANCE (PROGRESSION TRACKER)

- [x] **Day 1:** Project Architecture, Remotes & DataStore System (COMPLETED)
- [x] **Day 2:** Coin Spawning & Physics Stacking Engine (COMPLETED)
- [x] **Day 3:** Dash Bump Combat, Physics Ragdoll & Loot Explosion (COMPLETED)
- [/] **Day 4:** Safe Zone Bank Vault, Multipliers & DataStore Auto-Saving (IN PROGRESS)
- [ ] **Day 5:** Sound Matrix, VFX Emitters & Elastic UI Tweens
- [ ] **Day 6:** Monetization Handlers, Roblox Group API & AFK Rewards
- [ ] **Day 7:** Networking Optimization, Part Pooling & Stress Testing

---

## 📋 SCRIPTER TASK BREAKDOWN

### 🟦 DAY 1: Framework, Remotes & DataStore Foundation (COMPLETED)
> **Focus:** Server-Client Architecture & Data Persistence.

- [x] **1.1 Server-Client Architecture Setup**
  - Create standard modular directory structure (`ReplicatedStorage.Modules`, `ServerScriptService.Services`, `StarterPlayerScripts.Controllers`).
  - Set up `RemoteEvent` & `RemoteFunction` registry under `ReplicatedStorage.Remotes`.
- [x] **1.2 DataStore Service (`DataStoreManager.luau`)**
  - Write robust `ProfileStore` handler with pcall wrappers and session locking.
  - Define player schema: `{Coins = 0, TotalBanked = 0, EquippedSkin = "Default", OwnedPasses = {}}`.
  - Add `BindToClose` and auto-save timer (every 5 minutes).
- [x] **1.3 Category-Scoped Logger System (`Logger.luau`)**
  - Integrated centralized category-scoped logger across all combat, input, state machine, and ragdoll modules.

---

### 🟩 DAY 2: Coin Spawner & Head-Stacking Engine (COMPLETED)
> **Focus:** Networked coin collection & custom physics sway calculations.

- [x] **2.1 Server Coin Spawner (`CoinSpawner.luau`)**
  - Script server spawner for coin nodes across Zone 1, 2, and 3.
  - Implement node respawn logic (3s interval).
- [x] **2.2 Spring-Loaded Stacking Engine (`StackServer.luau` & `StackVisualizer.luau`)**
  - Attach item models sequentially to player character (`Character.Head` socket).
  - Calculate dynamic stack height and center of mass.
  - Implement visual cap (render max 30 parts on head; display numerical multiplier text for stack count > 30).

---

### 🟥 DAY 3: Dash Bump Combat, Ragdoll & Loot Explosion (COMPLETED)
> **Focus:** Character physics manipulation, ragdoll state transition & part scattering.

- [x] **3.1 Dash Bump Combat (`CombatServer.luau` & `InputController.luau`)**
  - Bind `E` key (PC) and ContextActionService Touch Button (Mobile).
  - Enforce server-side 5-second cooldown validation.
  - Script continuous 0.3s Heartbeat 3D swept hitbox check (`Workspace:Spherecast`).
  - Apply knockback impulse scaling with target's stack size.
- [x] **3.2 Decoupled Hitbox Engine & Dummy Spawner (`HitboxService.luau` & `DummySpawner.luau`)**
  - Measure character extents (`character:GetExtentsSize()`) and weld full-body `HitboxCapsule` parts.
  - Maintain 3 permanent color-coded target dummies in the arena with 3s void auto-respawning.
- [x] **3.3 Physics Ragdoll Handler (`RagdollModule.luau`)**
  - Disable `Motor6Ds`, substitute `BallSocketConstraints` + `NoCollisionConstraints`, disable `EvaluateStateMachine`, set `Humanoid.PlatformStand = true` for 2.5s.
  - Apply local-to-world 3D pitch/roll tumbling torque.
- [x] **3.4 Loot Explosion Engine (`LootExplosion.luau`)**
  - Instantly detach head stack on ragdoll impact.
  - Instantiate unanchored physical coin parts with random 360° radial velocity vectors.
  - Script vacuum collection window (10s lifetime) + automatic garbage collection despawn pool.

---

### 🟨 DAY 4: Banking Vault & Zone Multipliers (IN PROGRESS)
> **Focus:** Safe zone boundaries & multiplier cashout calculations.

- [x] **4.1 Safe Zone Bank Handler (`BankServer.luau`)**
  - Script Bank Vault Pad (`BankVaultPad` at `0, 0.5, -45`) with 3D Billboard label in lobby safe zone.
  - Disable `CombatServer` bump triggers (`SafeZone` FSM state) while player is inside safe zone.
- [x] **4.2 Multiplier & Banking Calculation**
  - Program cashout function: `BankedCash = StackCount * ZoneMultiplier`.
  - Add banked amount to player's permanent ProfileStore balance via `DataStoreManager.AddBankedCash()`.
  - Reset head stack count to 0.
- [x] **4.3 Leaderboard Handler (`leaderstats`)**
  - Script Leaderstats (`Coins`, `Stack`) on player list.

---

### 🟪 DAY 5: Audio Matrix, VFX & Elastic UI Tweens (NEXT UP)
> **Focus:** Sound pitch scaling, particle triggers & UI animation logic.

- [ ] **5.1 Pitch-Scaling Audio Matrix (`SoundManager.luau`)**
  - Program collection sound trigger with pitch shift (`PlaybackSpeed` +0.05 per pickup within 3s).
  - Script impact crash SFX trigger on ragdoll explosion.
  - Script cash register sound on banking.
- [ ] **5.2 VFX & Camera Shake Controller (`FXController.luau`)**
  - Trigger client particle sparks at head position on coin pickup.
  - Program directional camera shake script (`Humanoid.CameraOffset` noise lerp) when victim is bumped.
- [ ] **5.3 Elastic UI Tween Module (`UITween.luau`)**
  - Write reusable UI bounce scale utility using `TweenService` with `Enum.EasingStyle.Back`.
  - Hook UI tweens to wallet count changes and bump button press.

---

### 🟧 DAY 6: Monetization Handlers, Group Gate & AFK Rewards
> **Focus:** MarketplaceService integration & Roblox Social APIs.

- [ ] **6.1 Marketplace Handlers (`MonetizationServer.luau`)**
  - Script Gamepass check: **Super Glue** (Retain 50% stack on ragdoll explosion).
  - Script Gamepass check: **Mega Dash Range** (+100% hitbox radius).
  - Script DevProduct handler: **Instant Bank Teleport** (Prompt UI when stack > 50 in Zone 2/3).
  - Script DevProduct handler: **Nuclear Revenge** (Pop-up on ragdoll screen to strike attacker with lightning raycast).
- [ ] **6.2 Group API Loyalty Gate (`GroupGate.luau`)**
  - Call `Player:IsInGroup(GroupID)` on join.
  - Open lobby door & grant +20% permanent cash multiplier if true; prompt group join if false.
- [ ] **6.3 AFK Reward Matrix (`AFKRewards.luau`)**
  - Track player active session time; grant coin/boost rewards at 5m, 15m, 30m, and 60m marks.

---

### 🟥 DAY 7: Performance Optimization & Network Stress Testing
> **Focus:** Part pooling, network bandwidth optimization & bug fixing.

- [ ] **7.1 Unanchored Part Pooling (`PartPooler.luau`)**
  - Implement a part pool for dropped coins to prevent `Instance.new()` overhead during explosions.
  - Hard cap active server dropped coins to 50 max.
- [ ] **7.2 Mobile Touch Controls & UI Inset Polish**
  - Test touch button inputs on mobile emulator (`GuiService:GetGuiInset()`).
- [ ] **7.3 15-Player Multiplayer Stress Test**
  - Profile network usage (`Stats:GetTotalMemoryUsageMb()`), eliminate memory leaks, and fix stack sync desyncs under heavy action.
