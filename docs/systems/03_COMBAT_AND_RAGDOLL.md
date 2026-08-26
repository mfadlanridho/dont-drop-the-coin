# 📄 SYSTEM 03: DASH BUMP COMBAT, RAGDOLL & LOOT EXPLOSION

This document specifies the OOP StateMachine architecture, MovementMotor integration, AnimationControllerV2 system, Workspace:Spherecast continuous 3D swept hitboxes, HitboxService dynamic capsule bounding, DummySpawner 1-player testing, BallSocketConstraint + NoCollisionConstraint physical limb ragdolls, Gizmo debug visualizers, Developer Debug GUI controls, and category-scoped Logger integration for **Don't Drop The Coin!**.

---

## 🎯 OBJECTIVES
1. Enforce strict OOP state management using class-based state definitions with lifecycle hooks (`canEnter`, `enter`, `exit`, `update`) adapted from the *Roblox AI Workspace* pattern (`StateMachine.luau`).
2. Maintain **persistent context tables** (`PlayerFSM.luau`) per player to guarantee state variables (`dashConnection`) are preserved across `enter()` and `exit()` hooks.
3. Integrate **`MovementMotor.luau`** (`src/shared/Utils/MovementMotor.luau`) for unified, leak-proof creation, steering capture (`AutoRotate`), and destruction of `LinearVelocity` physics constraints.
4. Integrate **`AnimationControllerV2`** (`src/client/Animation/`) for client-side preloading, sequence playback, and skill animation management (`Config.DASH_ANIMATION_ID`).
5. Decouple 3D hitbox management into **`HitboxService.luau`**: measure character extents (`character:GetExtentsSize()`), weld transparent `HitboxCapsule` parts, and query target hitboxes cleanly.
6. Program continuous **0.3s Heartbeat Hitbox Sweep** in `CombatServer.luau`: runs `Spherecast` (4.5-stud radius) and `GetPartBoundsInBox` spatial queries every frame as character lunges forward.
7. Maintain 3 permanent target dummies in the arena via **`DummySpawner.luau`** with 3-second void respawning for 1-Player solo testing.
8. Program a **2.5-Second Physics Ragdoll** state (`Humanoid.PlatformStand = true`, `Humanoid.EvaluateStateMachine = false`, dynamic `BallSocketConstraint` + `NoCollisionConstraint` physical limb sockets, `Enum.HumanoidStateType.Physics`, and local-to-world 3D pitch/roll tumbling torque).
9. Render 3D object-pooled debug gizmos (`DashBumpGizmoController.luau`) in Studio for trajectory lines, swept wire spheres, red impact hit markers, golden hit labels, and continuous green 3D wireframe boxes (`AlwaysShowHitboxes`).
10. Integrate **Category-Scoped Logger System** (`Logger.luau`) across `Input`, `Combat`, `FSM`, and `Ragdoll` modules.
11. Provide interactive **Developer Debug GUI** controls (`Combat Debug` panel) for live in-game testing of knockback, ragdoll, `Always Show Hitboxes` toggle, and full combat API simulations.

---

## 📐 OOP STATE MACHINE (FSM) ARCHITECTURE

```mermaid
stateDiagram-v2
    [*] --> NormalState: Player Spawns (StateMachine.new)

    state NormalState {
        [*] --> Walking
        Walking --> DashingState: Press E / Mobile Touch Button
    }

    DashingState --> Cooldown: MovementMotor Parabolic Curve & Continuous 0.3s Hitbox Sweep
    Cooldown --> NormalState: 5.0 Seconds Elapsed

    NormalState --> SafeZoneState: Enter Ground Lobby Safe Zone
    SafeZoneState --> NormalState: Exit Ground Lobby

    NormalState --> RagdollState: Struck by Spherecast Bump / Hazard
    DashingState --> RagdollState: Struck Mid-Dash

    state RagdollState {
        [*] --> CreateBallSocketJoints
        CreateBallSocketJoints --> EnableNoCollisionConstraints
        EnableNoCollisionConstraints --> ApplyLocalWorldTumbleTorque
        ApplyLocalWorldTumbleTorque --> LaunchImpulse: Apply Stack-Scaled Knockback
        LaunchImpulse --> ScatterLootCoins: Detach & Explode Stack (360° Arc)
        ScatterLootCoins --> Recovering: Wait 2.5 Seconds
    }

    Recovering --> NormalState: Re-enable Motor6Ds & Stand Up
```

---

## 📂 REGISTERED STATE CLASSES, COMBAT & GIZMOS

| Module File | Role / Purpose | Technical Implementation |
| --- | --- | --- |
| **`StateMachine.luau`** | Core OOP State Machine class | Manages lifecycle hooks (`canEnter`, `enter`, `exit`, `update`) |
| **`PlayerFSM.luau`** | Persistent context & FSM manager | Reuses `PlayerContexts[player]` & manages client hook execution |
| **`MovementMotor.luau`** | Reusable physics motor class | Handles `LinearVelocity`, steering capture, and `motor:destroy()` |
| **`HitboxService.luau`** | Decoupled 3D Hitbox Service | Measures `character:GetExtentsSize()`, welds `HitboxCapsule`, queries hitboxes |
| **`DummySpawner.luau`** | Target Dummy Spawner Service | Spawns 3 permanent target arena dummies with 3s void auto-respawning |
| **`Logger.luau`** | Category-scoped debug logging | Centralized logging (`Input`, `Combat`, `FSM`, `Ragdoll`) |
| **`CombatServer.luau`** | Server combat & hitbox service | Continuous 0.3s Heartbeat hitbox loop, `BumpVictim` API, and launch vectors |
| **`RagdollModule.luau`** | Physics ragdoll transition module | Replaces `Motor6Ds` with `BallSocketConstraint` & `NoCollisionConstraint` sockets |
| **`AnimationControllerV2.luau`** | Client animation engine | Handles track loading, preloading, and sequence crossfading |
| **`DashingState.luau`** | Dash Bump execution state | Uses `MovementMotor` parabolic velocity curve & animation playback |
| **`DashBumpGizmoController.luau`**| Client debug gizmo controller | Renders cyan sweep lines, red impact trajectory, and 3D wireframe boxes |
| **`DebugGuiController.luau`** | Developer Debug GUI controller | Renders `Combat Debug` panel with `Always Show Hitboxes` toggle and dummy spawner |

---

## ⚙️ COMBAT & PHYSICS SPECIFICATION TABLE

| Parameter | Value | Description |
| --- | --- | --- |
| **`BUMP_COOLDOWN`** | `5.0` seconds | Server-enforced cooldown between Dash Bump casts |
| **`DASH_DISTANCE`** | `15.0` studs | Exact forward distance character lunges during dash |
| **`DASH_DURATION`** | `0.3` seconds | Duration of forward dash movement |
| **`DASH_ANIMATION_ID`**| `"rbxassetid://102382549309160"` | Roblox Asset ID for custom Dash animation track |
| **`SPHERECAST_RADIUS`**| `4.5` studs | Radius of 3D swept sphere for collision detection |
| **`BASE_KNOCKBACK`** | `50` impulse | Base physical force applied to victim |
| **`STACK_KNOCKBACK_MULT`**| `2.0` per coin | Additional knockback force added per coin in victim's stack |
| **`RAGDOLL_DURATION`** | `2.5` seconds | Duration character remains in physical flopping ragdoll |
| **`LOOT_DESPAWN_TIME`** | `10.0` seconds | Lifetime of scattered physical coins before despawn pool recycling |
| **`MAX_DROPPED_COINS`** | `50` max | Hard server cap on active dropped coin parts to preserve performance |

---

## 🛠️ API & REMOTES CONTRACT

- **`HitboxService.GetTargetHitboxes(excludingPlayer)`**: Returns array of `HitboxCapsule` parts for all active opponent players & arena dummies.
- **`CombatServer.BumpVictim(attackerPlayer, victimPlayer)`**: Server API to trigger complete combat bump pipeline (knockback, 360° stack explosion, 2.5s ragdoll, and client hit visualizers).
- **`DummySpawner.CreateDummy(name, pos, color)`**: Spawns a 3D target dummy model in Workspace with automatic `HitboxCapsule` attachment.
- **`Remotes.DashBump` (`RemoteEvent`)**: `Client -> Server`: `DashBump:FireServer(clientTargetVictim)`
- **`Remotes.DashBumpHit` (`RemoteEvent`)**: `Server -> Client`: `DashBumpHit:FireAllClients(attacker, victimName, hitPos, force)`
- **`Remotes.TriggerRagdoll` (`RemoteEvent`)**: `Server -> Client`: `TriggerRagdoll:FireClient(victimPlayer, duration, launchVector)`
- **`Remotes.SimulateDashBump` (`RemoteEvent`)**: `Client -> Server`: Debug simulation trigger for `BumpVictim(nil, player)`.
- **`Remotes.SpawnTestDummy` (`RemoteEvent`)**: `Client -> Server`: Debug trigger to spawn a test target dummy.

---

## 🛠️ POLISH & FUTURE BACKLOG

The following items are documented for post-MVP combat & physics polish passes:

1. **Delta Movement Sweep Algorithm (`CombatServer.luau`):**
   * *Target:* Replace fixed forward spherecast sweeps with an incremental `deltaVector = currentPos - lastPos` sweep on `RunService.Heartbeat`. Eliminates phantom forward reach into un-traversed space and guarantees exact physical path coverage.

2. **`SPHERECAST_RADIUS` Body-Width Tuning (`Config.luau`):**
   * *Target:* Tune `SPHERECAST_RADIUS` from 4.5 studs down to 2.0–2.5 studs to match character shoulder width, ensuring opponents standing 6+ studs away from a short lunge are not struck.

3. **Client-Targeted Ping Reconciliation:**
   * *Target:* Enhance client target validation payload (`findTargetVictimOnClient()`) to reconcile 100ms–150ms mobile ping delays with server distance validation.

4. **Residual Knockback Force Dampening:**
   * *Target:* Frame-delayed velocity dampening on second physics tick following impact.

5. **Ragdoll Recovery Duration Tuning:**
   * *Target:* Tune `Config.RAGDOLL_DURATION` down to 1.5s - 2.0s or scale recovery timing based on coin stack count.

6. **Get-Up Recovery Animation & Blending:**
   * *Target:* Integrate custom "Get-Up" recovery animation tracks via `AnimationControllerV2` with smooth crossfading into `NormalState`.
