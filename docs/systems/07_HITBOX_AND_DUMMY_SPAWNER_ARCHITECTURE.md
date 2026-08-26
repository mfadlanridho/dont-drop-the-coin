# 📄 SYSTEM 07: HITBOX SERVICE & DUMMY SPAWNER ARCHITECTURE

This document specifies the decoupled 3D Hitbox Capsule Engine (`HitboxService.luau`) and the Automatic Target Dummy Spawner Service (`DummySpawner.luau`) for **Don't Drop The Coin!**.

---

## 🎯 OBJECTIVES
1. Decouple character collision volume creation and spatial queries from combat services into a standalone, reusable **`HitboxService.luau`** service.
2. Dynamically measure character bounding extents (`character:GetExtentsSize()`) to scale full-body `HitboxCapsule` parts for any player avatar package (blocky R15, anthro, small, tall).
3. Weld transparent, massless `HitboxCapsule` parts (`CanCollide = false`, `CanQuery = true`) to `HumanoidRootPart` on character spawn.
4. Maintain 3 permanent color-coded target dummies in the arena via **`DummySpawner.luau`** with automatic 3-second void respawning for 1-Player solo play testing.
5. Provide continuous `RenderStepped` 3D wireframe box visualization in Studio via `DashBumpGizmoController.luau` when `AlwaysShowHitboxes` is toggled ON in the Developer Debug GUI.

---

## 📐 HITBOX & DUMMY ARCHITECTURE

```mermaid
graph TD
    A[Player / Dummy Spawns] --> B[HitboxService.CreateHitbox]
    B --> C[character:GetExtentsSize]
    C --> D[Calculate Dimensions: max(4.0, extents + 0.5)]
    D --> E[Create HitboxCapsule Part & Weld to HRP]
    
    F[CombatServer Dash Bump] --> G[HitboxService.GetTargetHitboxes]
    G --> H[Continuous 0.3s Heartbeat Loop]
    H --> I[Workspace:Spherecast & GetPartBoundsInBox]
    I --> J[Trigger Knockback & Ragdoll on Hit]

    K[DummySpawner.Init] --> L[Spawn 3 Arena Target Dummies]
    L --> M[Void Monitor Loop: Check Y < -20]
    M -->|Fell in Void| N[Respawn Target Dummy after 3s]
```

---

## 📂 REGISTERED MODULES

| Module File | Location | Role / Purpose |
| --- | --- | --- |
| **`HitboxService.luau`** | `src/server/Services/HitboxService.luau` | Manages `HitboxCapsule` creation, extents measuring, and `GetTargetHitboxes()` queries. |
| **`DummySpawner.luau`** | `src/server/Services/DummySpawner.luau` | Spawns 3 permanent target arena dummies with 3s void auto-respawning. |
| **`CombatServer.luau`** | `src/server/Services/CombatServer.luau` | Queries `HitboxService.GetTargetHitboxes()` for continuous 0.3s Heartbeat hitbox sweeps. |
| **`DashBumpGizmoController.luau`** | `src/client/Controllers/` | Renders continuous green `BoxHandleAdornment` 3D wireframe boxes around `HitboxCapsules`. |

---

## 📐 DYNAMIC HITBOX SIZING ALGORITHM

```luau
-- HitboxService.luau sizing math
local extents = character:GetExtentsSize()
local hitboxWidth  = math.max(4.0, extents.X + 0.5)
local hitboxHeight = math.max(5.5, extents.Y + 0.5)
local hitboxDepth  = math.max(4.0, extents.Z + 0.5)

hitbox.Size = Vector3.new(hitboxWidth, hitboxHeight, hitboxDepth)
```

---

## 📍 DUMMY SPAWN CONFIGURATION

| Dummy Name | Spawn Position | Color | Role |
| --- | --- | --- | --- |
| **`TargetDummy_Center`** | `Vector3.new(0, 4, 16)` | `Color3.fromRGB(255, 120, 0)` | Central Arena Target Dummy |
| **`TargetDummy_Left`** | `Vector3.new(-12, 4, 22)` | `Color3.fromRGB(0, 200, 255)` | Left Flank Target Dummy |
| **`TargetDummy_Right`** | `Vector3.new(12, 4, 22)` | `Color3.fromRGB(255, 50, 200)` | Right Flank Target Dummy |

---

## 🛠️ API CONTRACT

- **`HitboxService.CreateHitbox(character: Model): BasePart?`**: Creates and welds a full-body `HitboxCapsule` to the model.
- **`HitboxService.GetHitbox(model: Instance): BasePart?`**: Retrieves or creates the `HitboxCapsule` for a player or NPC model.
- **`HitboxService.GetTargetHitboxes(excludingPlayer: Player?): { BasePart }`**: Returns an array of `HitboxCapsule` parts for all active opponent players and NPC dummies.
- **`DummySpawner.CreateDummy(name, pos, color): Model`**: Spawns a 3D target dummy model in Workspace with automatic `HitboxCapsule` attachment.
