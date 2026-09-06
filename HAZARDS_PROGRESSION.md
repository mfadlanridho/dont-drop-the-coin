# ⚠️ ENVIRONMENTAL HAZARDS — STEP-BY-STEP PROGRESSION

**Objective:** Implement, calibrate, and test Zone 2 & Zone 3 environmental hazards in isolated, bite-sized phases.  
**Philosophy:** Complete, test, and tune one hazard at a time before moving to the next.

---

## 🚦 MILESTONE TRACKER

| Phase | Hazard Name | Target Zone | Complexity | Status |
| :---: | :--- | :--- | :---: | :---: |
| **Phase 1** | **`DisappearingPlatform`** | Zone 3 (*The Void Lunatic*) | Low (Static State Cycle) | 🟢 **CODE COMPLETE (TESTING)** |
| **Phase 2** | **`PistonCrusher`** | Zone 2 (*The Chaos Factory*) | Medium (1-Axis Motion + Squash) | ⚪ PENDING |
| **Phase 3** | **`PendulumObstacle`** | Zone 2 (*The Chaos Factory*) | High (Harmonic Rotation + Fling) | ⚪ PENDING |

---

## 📋 DETAILED PHASE BREAKDOWN

### 🟢 PHASE 1: Disappearing Platform (`DisappearingPlatform`)
> **Focus:** Non-moving interactive floor hazard. Player steps on platform $\rightarrow$ warning phase $\rightarrow$ collision drops $\rightarrow$ player falls $\rightarrow$ platform regenerates.

#### Tasks:
- [x] **1.1 Core OOP Component (`src/server/Hazards/DisappearingPlatform.luau`)**
  - [x] Implement state machine: `Stable` $\rightarrow$ `Warning` $\rightarrow$ `Vanished` $\rightarrow$ `Regenerate`.
  - [x] Integrate `SignalModule` pub/sub events (`Triggered`, `Vanished`, `Regenerated`).
  - [x] Support both single `BasePart` and multi-part `Model` assemblies.
  - [x] Cache original colors, transparencies, and collidability per part.
  - [x] Debounce trigger to prevent re-activation while cycle is active.
- [x] **1.2 Visual & Attribute Tuning**
  - [x] Warning phase: Smooth color lerp to `WarningColor` (default `Color3.fromRGB(255, 60, 60)`) + slight opacity shift.
  - [x] Disappear phase: Set `CanCollide = false` and `Transparency = 1`.
  - [x] Reappear phase: Restore collision and original appearance.
  - [x] Expose configurable attributes on parts/models:
    - `WarningDelay` (default `0.85s`)
    - `RespawnDelay` (default `2.5s`)
    - `WarningColor` (default `255, 60, 60`)
- [x] **1.3 Service Orchestration (`DisappearingPlatformService.luau`)**
  - [x] Create dedicated `DisappearingPlatformService.luau` in `src/server/Services/`.
  - [x] Scan and monitor `Workspace.Hazards.DisappearingPlatforms`.
  - [x] Listen to CollectionService tag `Hazard_DisappearingPlatform`.
  - [x] Register `DisappearingPlatformService` in `Main.server.luau`.
- [ ] **1.4 Verification & Playtesting**
  - [ ] Place test platform in Studio.
  - [ ] Walk across platform: verify warning flash, drop, and respawn feel responsive and fair.

---

### ⚪ PHASE 2: Piston Crusher (`PistonCrusher`)
> **Focus:** 1-axis vertical mechanical slam hazard. Periodic telegraph $\rightarrow$ violent slam $\rightarrow$ outward squash knockback into ragdoll & coin explosion.

#### Tasks:
- [ ] **2.1 Directional CombatServer Extension**
  - [ ] Update `CombatServer.BumpVictimModel()` in `src/server/Services/CombatServer.luau` to accept optional `customLaunchVector: Vector3?`.
- [ ] **2.2 Core OOP Component (`src/server/Hazards/PistonCrusher.luau`)**
  - [ ] Implement cycle: Ceiling Dwell $\rightarrow$ Anticipation Jitter $\rightarrow$ Slam $\rightarrow$ Floor Dwell $\rightarrow$ Retract.
  - [ ] Apply kinematic `AssemblyLinearVelocity` during stroke so physics solver registers downward momentum.
  - [ ] Compute outward horizontal launch vector from piston center to player HRP ($+35$ vertical lift).
  - [ ] Add per-character hit debounce per cycle.
  - [ ] Expose configurable attributes:
    - `DropDistance` (default `12` studs)
    - `CycleTime` (default `3.0s`)
    - `AnticipationTime` (default `0.25s`)
    - `PhaseOffset` (default `0.0s`)
- [ ] **2.3 Service Integration**
  - [ ] Wire `PistonCrusher` into `HazardService.luau`.
  - [ ] Scan `Workspace.Hazards.Pistons` and tag `Hazard_Piston`.
- [ ] **2.4 Verification & Playtesting**
  - [ ] Place test piston in Studio.
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
