# 🛠️ DON'T DROP THE COIN! — CORE SYSTEMS SPECIFICATION

This document outlines the complete technical breakdown of core systems required for the **Don't Drop The Coin!** Roblox MVP.

---

## 🛠️ 1. COIN COLLECTION & TRAVERSAL STACKING SYSTEM
- **Coin Spawners**: Zone-based floating coin node spawners (Zone 1 = 1x, Zone 2 = 2x, Zone 3 = 3x value) with 3-second node respawn timers.
- **Head Stack Socket**: Snap collected coin models sequentially to the player's `Character.Head` socket.
- **Traversal Modifier**: Dynamic sway and inertia calculations. As `stackCount` increases:
  - Center of mass shifts upwards.
  - Stack sways and lags behind character movement inputs using Lerp / Angular spring vectors.
  - Jump control and balance become progressively harder on higher stacks.
  - Render cap: Maximum 30 physical mesh parts rendered on head (displays floating numerical multiplier for stacks > 30 to preserve mobile performance).

---

## ⚔️ 2. ABILITY SYSTEM ("DASH BUMP")
- **Controls**: Bound to `E` key (PC) and an on-screen touch button (Mobile via `ContextActionService`).
- **Cooldown**: Enforced 5-second cooldown with an elastic UI radial timer.
- **Hitbox & Impulse**: Forward Raycast / OverlapParams check. When dashing into an opponent, apply knockback impulse vector scaled proportionally to the victim's stack height.

---

## 👾 3. ENEMY BOT SYSTEM ("GLITCH DRONE")
- **AI Hunter Monster**: Patrols **Zone 3 (The Void Lunatic)** sky platforms.
- **Targeting Logic**: Scans for nearby players, prioritizing players carrying tall, high-value coin stacks.
- **Attack Effect**: Strikes target player, triggering an instant 2.5-second physics ragdoll state and a full stack loot explosion.

---

## 💥 4. RAGDOLL & LOOT EXPLOSION ENGINE
- **Ragdoll Transition**: Triggered instantly by player Bump, mechanical traps, or AI Drone hit. Temporarily disables `Motor6D` joints / enables `PlatformStand` for 2.5 seconds with backward launch impulse.
- **Stack Detachment**: Head stack detaches immediately upon impact.
- **Loot Scattering**: Converts stack into unanchored physical coin models scattering in a 360-degree radial arc.
- **Vacuum Collection & Pooling**: Dropped coins can be picked up by any nearby player for 10 seconds before being recycled into an object pool (hard cap 50 dropped coins server-wide).

---

## 🏦 5. SAFE ZONE BANK & ZONE MULTIPLIERS
- **Safe Zone Lobby**: Ground floor 100% safe zone. Entering disables PvP combat and overrides ragdoll.
- **Bank Vault Cashout**: Walking onto the Bank Vault pad calculates total earnings:
  $$\text{Banked Cash} = \text{Stack Coins} \times \text{Zone Multiplier}$$
- **Leaderboards**: Session leaderboard & global ordered DataStore leaderboard for Top Banked Cash.

---

## 💾 6. DATASTORE & PERSISTENCE SYSTEM
- **Player Schema**: Saves `{Coins, TotalBanked, EquippedSkin, OwnedPasses}`.
- **Reliability**: Uses session locking, pcall wrappers, 5-minute auto-save timers, and `BindToClose` on server shutdown.

---

## 🔊 7. JUICINESS ENGINE (AUDIO, VFX & ELASTIC UI)
- **Audio Pitch Scaling**: Pickup sound (`Ding-Ching!`) increases in pitch (`PlaybackSpeed` +0.05 per pickup within a 3s window).
- **Impact SFX**: Loud `MEGA-CRASH!` sound + cartoonish grunt on ragdoll launch; cash register sound on banking.
- **VFX**: Radial particle sparkles on head on collection; directional camera shake on hit.
- **Elastic UI Tweens**: Bouncing scale animations (`TweenService` Elastic/Back) on wallet text updates and shop pop-ups.

---

## 💸 8. MONETIZATION & RETENTION HOOKS
- **Gamepasses**:
  - *"Super Glue"* (Retain 50% stack on ragdoll wipeout).
  - *"Mega Dash Range"* (+100% bump hitbox radius).
- **Developer Products**:
  - *"Instant Bank Teleport"* (Emergency prompt when stack > 50 in Zone 2/3).
  - *"Nuclear Revenge"* (Defeat pop-up to strike attacker with map-wide lightning).
- **Group Loyalty Gate**: Checks `Player:IsInGroup(GroupID)` to unlock Lobby Vault door (+20% permanent cash multiplier).
- **AFK Reward Matrix**: Rewards active play at 5m, 15m, 30m, and 60m session intervals.
