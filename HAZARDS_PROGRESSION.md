# ⚠️ ENVIRONMENTAL HAZARDS — STEP-BY-STEP PROGRESSION

**Objective:** Implement, calibrate, and test Zone 2 & Zone 3 environmental hazards in isolated, bite-sized phases.  
**Philosophy:** Complete, test, and tune one hazard at a time before moving to the next.

---

## 🚦 MILESTONE TRACKER

| Phase | Hazard Name | Target Zone | Complexity | Status |
| :---: | :--- | :--- | :---: | :---: |
| **Phase 1** | **`DisappearingPlatform`** | Zone 3 (*The Void Lunatic*) | Low (Static State Cycle) | ✅ **100% COMPLETE** |
| **Phase 2** | **`PistonCrusher`** | Zone 2 (*The Chaos Factory*) | Medium (1-Axis Motion + Squash) | 🟡 **UP NEXT** |
| **Phase 3** | **`PendulumObstacle`** | Zone 2 (*The Chaos Factory*) | High (Harmonic Rotation + Fling) | ⚪ PENDING |

---

## 📋 DETAILED PHASE BREAKDOWN

### ✅ PHASE 1: Disappearing Platform (`DisappearingPlatform`)
> **Focus:** Non-moving interactive floor hazard. Player steps on platform $\rightarrow$ warning phase $\rightarrow$ collision drops $\rightarrow$ player falls $\rightarrow$ platform regenerates.

#### Tasks:
- [x] **1.1 Core OOP Component (`src/server/Hazards/DisappearingPlatform.luau`)**
  - [x] Implement state machine: `Stable` $\rightarrow$ `Warning` $\rightarrow$ `Vanished` $\rightarrow$ `Regenerate`.
  - [x] Integrate `SignalModule` pub/sub events (`Triggered`, `Vanished`, `Regenerated`).
  - [x] Support both single `BasePart` and multi-part `Model` assemblies.
  - [x] Replicate state via `PlatformState` Attribute (`"Stable"`, `"Warning"`, `"Vanished"`).
  - [x] Add 0.5s post-regeneration grace debounce to prevent immediate re-triggering.
- [x] **1.2 Visual & Attribute Tuning (`Config.luau` Integration)**
  - [x] Centralize defaults in `src/shared/Config/init.luau` (`Config.HAZARDS.DISAPPEARING_PLATFORM`).
  - [x] Expose configurable attributes on parts/models with Config fallback:
    - `WarningDelay` (default `0.85s`)
    - `RespawnDelay` (default `2.5s`)
    - `WarningColor` (default `255, 60, 60`)
- [x] **1.3 Dedicated Service Orchestration (`DisappearingPlatformService.luau`)**
  - [x] Create decoupled `DisappearingPlatformService.luau` in `src/server/Services/`.
  - [x] Scan and monitor `Workspace.Hazards.DisappearingPlatforms`.
  - [x] Listen to CollectionService tag `Hazard_DisappearingPlatform`.
  - [x] Register `DisappearingPlatformService` in `Main.server.luau`.
- [x] **1.4 Client-Side Deterministic Collision (`DisappearingPlatformController.luau`)**
  - [x] Listen to replicated `PlatformState` on client.
  - [x] Smooth local 60+ FPS color lerp with explicit tween cancellation (kills "stuck in red" bug).
  - [x] 0ms local `CanCollide = false` and `Transparency = 1`.
  - [x] Force `HumanoidStateType.Freefall` on standing character (kills floating humanoid glitch).
  - [x] Hide and restore attached GUI billboard labels.
  - [x] Register controller in `src/client/Main.client.luau`.
- [x] **1.5 Studio Verification & Playtesting**
  - [x] Placed `TestPlatform_Demo` in `Workspace.Hazards.DisappearingPlatforms`.
  - [x] Verified responsive step trigger, clean drop into gap, and safe regeneration.

---

### 🟢 PHASE 2: Piston Crusher (`PistonCrusher`)
> **Focus:** 1-axis vertical mechanical slam hazard. Periodic telegraph $\rightarrow$ violent slam $\rightarrow$ outward squash knockback into ragdoll & coin explosion.

#### Tasks:
- [x] **2.1 Directional CombatServer Extension**
  - [x] Updated `CombatServer.BumpVictimModel()` in `src/server/Services/CombatServer.luau` to accept optional `customLaunchVector: Vector3?`.
- [x] **2.2 Core OOP Component (`src/server/Hazards/PistonCrusher.luau`)**
  - [x] Implement cycle: Ceiling Dwell $\rightarrow$ Anticipation Jitter (0.25s) $\rightarrow$ Slam (0.20s) $\rightarrow$ Floor Dwell (0.35s) $\rightarrow$ Retract (1.10s).
  - [x] Apply kinematic `AssemblyLinearVelocity` during downward stroke so physics solver registers downward momentum.
  - [x] Compute outward horizontal launch vector from piston center to player HRP ($+35$ vertical lift).
  - [x] Add per-character hit debounce per cycle.
  - [x] Integrate `SignalModule` events (`Slammed`, `HitVictim`).
  - [x] Expose configurable attributes (with `Config.HAZARDS.PISTON_CRUSHER` fallbacks):
    - `DropDistance` (default `10` studs)
    - `CycleTime` (default `3.0s`)
    - `AnticipationTime` (default `0.25s`)
    - `PhaseOffset` (default `0.0s`)
- [x] **2.3 Streaming-Native Service Orchestration (`PistonCrusherService.luau`)**
  - [x] Create dedicated `PistonCrusherService.luau` in `src/server/Services/`.
  - [x] Primary: 100% Streaming-Native CollectionService (`Hazard_Piston`).
  - [x] Server convenience: Auto-tag parts placed in `Workspace.Hazards.Pistons`.
  - [x] Register `PistonCrusherService` in `Main.server.luau`.
- [x] **2.4 Studio Verification & Playtesting**
  - [x] Placed industrial crush frame & `TestPiston_Demo` in `Workspace.Hazards.Pistons`.
  - [ ] Stand under piston during slam: verify outward squash launch, 2.5s ragdoll, and coin scatter.

---

### ⚪ PHASE 3: Swinging Pendulum (`PendulumObstacle`)
> **Focus:** Rotational harmonic obstacle. Continuous smooth sine oscillation $\rightarrow$ tangential directional fling into ragdoll & coin explosion.

#### Tasks:
- [ ] **3.1 Core OOP Component (`src/server/Hazards/PendulumObstacle.luau`)**
  - [ ] Implement deterministic harmonic motion: $\theta(t) = \theta_{\max} \cdot \sin(\omega t + \phi)$ using `workspace:GetServerTimeNow()`.
  - [ ] Calculate instantaneous angular velocity and apply tangential `AssemblyLinearVelocity`.
  - [ ] Launch struck players in the exact direction of the pendulum's swing vector.
  - [ ] Add per-character hit debounce per swing pass.
  - [ ] Expose configurable attributes:
    - `SwingAngle` (default `50°`)
    - `SwingSpeed` (default `2.5`)
    - `ArmLength` (default `10` studs)
    - `PhaseOffset` (default `0.0s`)
- [ ] **3.2 Service Integration**
  - [ ] Wire `PendulumObstacle` into `HazardService.luau`.
  - [ ] Scan `Workspace.Hazards.Pendulums` and tag `Hazard_Pendulum`.
- [ ] **3.3 Verification & Playtesting**
  - [ ] Place test pendulum in Studio over a walkway.
  - [ ] Walk into swing path: verify directional fling knocks player sideways into the pit.

---

## 🎯 PLAYTEST & TUNING CHECKLIST

- [ ] **Phase 1 Complete:** Disappearing platforms feel predictable, telegraphing gives enough time to react, and regeneration doesn't trap players.
- [ ] **Phase 2 Complete:** Pistons give clear audio/visual telegraph, slam feels heavy, squash knocks players away cleanly without double-hitting.
- [ ] **Phase 3 Complete:** Pendulums swing smoothly with zero network jitter, hitboxes align with visual blades, and knockbacks send players over catwalk edges.
