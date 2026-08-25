# 📄 SYSTEM 03: DASH BUMP COMBAT, RAGDOLL & LOOT EXPLOSION

This document specifies the OOP StateMachine architecture, Dash Bump combat ability mechanics, 2.5-second physics ragdoll transitions, and unanchored loot explosion scattering for **Don't Drop The Coin!**.

---

## 🎯 OBJECTIVES
1. Enforce strict OOP state management using class-based state definitions with lifecycle hooks (`canEnter`, `enter`, `exit`, `update`) adapted from the *Roblox AI Workspace* pattern (`StateMachine.luau`).
2. Program the **Dash Bump** ability (`E` key / Mobile touch button) with a 5-second server-verified cooldown and stack-scaled knockback impulse.
3. Program a **2.5-Second Physics Ragdoll** state (`Humanoid.PlatformStand = true`, `Motor6D` socket constraints).
4. Program the **Loot Explosion Engine**: Detach head stack, scatter glowing unanchored physical coin parts in a 360° radial arc, and enable 10-second vacuum pickups.

---

## 📐 OOP STATE MACHINE (FSM) ARCHITECTURE

```mermaid
stateDiagram-v2
    [*] --> NormalState: Player Spawns (StateMachine.new)

    state NormalState {
        [*] --> Walking
        Walking --> DashingState: Press E / Mobile Touch Button
    }

    DashingState --> Cooldown: Dash Impulse Complete (0.3s)
    Cooldown --> NormalState: 5.0 Seconds Elapsed

    NormalState --> SafeZoneState: Enter Ground Lobby Safe Zone
    SafeZoneState --> NormalState: Exit Ground Lobby

    NormalState --> RagdollState: Struck by Bump / Hazard / AI Monster
    DashingState --> RagdollState: Struck Mid-Dash

    state RagdollState {
        [*] --> DisableMotors
        DisableMotors --> LaunchImpulse: Apply Stack-Scaled Knockback
        LaunchImpulse --> ScatterLootCoins: Detach & Explode Stack (360° Arc)
        ScatterLootCoins --> Recovering: Wait 2.5 Seconds
    }

    Recovering --> NormalState: Re-enable Motors & Stand Up
```

---

## 📂 REGISTERED STATE CLASSES (`src/shared/Utils/States/`)

| State Class | Module File | Transition Rules (`canEnter`) | Lifecycle Hooks (`enter` / `exit`) |
| --- | --- | --- | --- |
| **`NormalState`** | `NormalState.luau` | Default gameplay state | Initializes normal character movement |
| **`DashingState`** | `DashingState.luau` | **Blocked if** `Ragdolled` or `SafeZone` | Triggers forward dash impulse |
| **`RagdollState`** | `RagdollState.luau` | **Blocked if** `SafeZone` | Disables Motor6Ds (2.5s) & re-enables on exit |
| **`SafeZoneState`**| `SafeZoneState.luau` | Always allowed | Grants PvP & ragdoll immunity inside lobby |

---

## ⚙️ COMBAT & RAGDOLL SPECIFICATION TABLE

| Parameter | Value | Description |
| --- | --- | --- |
| **`BUMP_COOLDOWN`** | `5.0` seconds | Server-enforced cooldown between Dash Bump casts |
| **`DASH_DURATION`** | `0.3` seconds | Duration of forward dash velocity impulse |
| **`BASE_KNOCKBACK`** | `50` impulse | Base physical force applied to victim |
| **`STACK_KNOCKBACK_MULT`**| `2.0` per coin | Additional knockback force added per coin in victim's stack |
| **`RAGDOLL_DURATION`** | `2.5` seconds | Duration character remains in unanchored physics ragdoll |
| **`LOOT_DESPAWN_TIME`** | `10.0` seconds | Lifetime of scattered physical coins before despawn pool recycling |
| **`MAX_DROPPED_COINS`** | `50` max | Hard server cap on active dropped coin parts to preserve performance |

---

## 🛠️ API & REMOTES CONTRACT

- **`Remotes.DashBump` (`RemoteEvent`)**:
  - `Client -> Server`: `DashBump:FireServer()`
- **`Remotes.TriggerRagdoll` (`RemoteEvent`)**:
  - `Server -> Client`: `TriggerRagdoll:FireClient(victimPlayer, duration)`
