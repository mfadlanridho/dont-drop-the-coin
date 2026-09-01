# System Specification 12: Universal Guard AI Engine

**Status:** IMPLEMENTED  
**Location:** `src/shared/AI/` & `src/server/Services/GuardAIService.luau`  

---

## 1. Overview

The **Universal Guard AI Engine** provides automated NPC enemy and hazard guard behaviors. Every AI model in the game uses standard Roblox **`Humanoid`** character navigation (`Humanoid:MoveTo()`), driven by a 4-state finite state machine (**`StateMachine.luau`**).

---

## 2. Architecture & Directory Layout

```
src/
├── shared/
│   └── AI/
│       ├── GuardAI.luau                <-- [Universal OOP Class Container]
│       └── States/
│           ├── IdleState.luau          <-- [Idle / Dormant Standby State]
│           ├── PatrolState.luau        <-- [Waypoint Patrol Loop State]
│           ├── ChaseState.luau         <-- [Target Pursuit State]
│           └── AttackState.luau        <-- [Lunge & Bump Ragdoll State]
│
└── server/
    └── Services/
        └── GuardAIService.luau         <-- [Server Service Orchestrator]
```

---

## 3. FSM State Lifecycle

```
 [ IDLE STATE ] ──(Platform Occupied)──► [ PATROL STATE ]
       ▲                                       │
       │                                       ▼
 (Exit Platform)                       (Player Detected)
       │                                       │
       │                                       ▼
 [ PATROL STATE ] ◄──(Target Exit)────── [ CHASE STATE ]
       │                                       │
       │                                       ▼
       └─────────────────────────────── [ ATTACK STATE ]
```

### State Specifications

| State Name | Trigger | Action / Movement | Exit Condition |
| --- | --- | --- | --- |
| **`IdleState`** | Server init or empty platform. | Calls `humanoid:MoveTo(currentPos)`. Hides default Roblox nametags. | Platform occupied $\rightarrow$ `PatrolState`. |
| **`PatrolState`** | Default active state. | Calls `humanoid:MoveTo(waypointPos)` in continuous loop between `Waypoints` parts. | Player detected on platform $\rightarrow$ `ChaseState`. |
| **`ChaseState`** | Player steps on platform. | Calls `humanoid:MoveTo(targetHrp.Position)`. | Distance $\le 5$ studs $\rightarrow$ `AttackState`. Player steps off platform $\rightarrow$ `PatrolState`. |
| **`AttackState`** | Target within 5 studs. | Executes lunge animation and calls `CombatServer.BumpVictimModel()`. | Attack delay finishes $\rightarrow$ `ChaseState`. |

---

## 4. Platform Spatial Footprint Boundary

To prevent guards from chasing players off platforms:
* **`isPlayerOnPlatform(player, platformPart)`**: Computes the exact 3D $X, Z$ bounding box of `PlatformFloor`.
* **Instant Cancellation:** The exact frame a player steps or jumps off `PlatformFloor`, `ChaseState.exit()` cancels active `MoveTo()` navigation and returns the guard to `PatrolState`.

---

## 5. Studio Workspace Integration

Platform models are placed inside **`Workspace.Hazards.Platforms`**:

```
Workspace/
└── Hazards/
    └── Platforms/
        └── Zone2_HumanoidPlatform_Demo (Model)
            ├── PlatformFloor           (Part)
            ├── Waypoints               (Folder: Waypoint1, Waypoint2)
            └── Guard_HumanoidWalker    (R15 Humanoid Guard Model)
```

`GuardAIService.luau` automatically scans `Workspace.Hazards.Platforms` and binds `GuardAI.new()` to all AI models.

---

## 6. Polishing Roadmap: Predictive Interception Pursuit System

For future AI polish iterations:
* **Velocity Vector Prediction:** Intercept player motion path ahead of time:
  $$\text{InterceptPos} = \text{targetHrp.Position} + (\text{targetHrp.AssemblyLinearVelocity} \times 0.4)$$
* **Delta-Distance Throttling:** Update `MoveTo()` destination only when target position changes $> 1.5$ studs or after 0.2s time limit, ensuring 100% fluid, continuous walk strides without micro-stuttering.

