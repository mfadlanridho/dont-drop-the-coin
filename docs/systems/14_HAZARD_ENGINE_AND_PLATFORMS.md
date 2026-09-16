# 📄 SYSTEM 14: ENVIRONMENTAL HAZARDS & MOVING PLATFORMS ARCHITECTURE

This document specifies the technical architecture, networking, physics considerations, current pilot implementation, and the future deterministic scaling model for **Environmental Hazards and Moving Platforms** across Zones 1 through 10 in **Don't Drop The Coin!**.

---

## 🎯 1. OBJECTIVES & PRINCIPLES
1. **Level-Design Decoupling (Socket Pattern)**: Map builders place spatial anchor parts (`SOCKET_*`) with custom Attributes (`HazardType`, `Span`, `Speed`, `TravelUp`, `Diameter`) rather than hardcoding coordinates in scripts.
2. **Friction & Character Traction**: Moving platforms must transfer tangential momentum and vertical velocity to riding characters (`AssemblyLinearVelocity` / `AssemblyAngularVelocity`) so players do not slip off, hitch, or clip through floors.
3. **Multi-Zone Scalability**: Support dozens of dynamic obstacles across 10 tower zones without degrading server tick rates.
4. **Single Source of Truth**: Centralized orchestration via `HazardService.luau`.

---

## 🏗️ 2. DIRECTORY ARCHITECTURE

```
src/
├── server/
│   ├── Services/
│   │   └── HazardService.luau         <-- Central orchestrator; scans sockets & binds CollectionService
│   │
│   └── Hazards/
│       ├── RotatingPlatform.luau      <-- Zone 2 rotating circular disc (HingeConstraint Motor)
│       ├── VerticalLift.luau          <-- Zone 2 vertical crane elevator (Kinematic AssemblyVelocity)
│       ├── DisappearingPlatform.luau  <-- Zone 3 fading floor tiles (Server-authoritative lifecycle)
│       └── PistonCrusher.luau         <-- Mechanical slam crushers (Impulse, ragdoll & coin drop)
```

---

## ⚙️ 3. IMPLEMENTED HAZARDS (ZONE 2 & 3 PILOT)

### A. Rotating Platform (`RotatingPlatform.luau`)
- **Target Socket**: `SOCKET_RotatingPlatform` in `Zone2_ChaosFactory.FutureHazardSockets`.
- **Target Geometry**: `RP_Hub`, `RP_Disc`, `RP_Body`, `RP_Ring` in `Route.CranePlatform`.
- **Physics Mechanism**:
  - `RP_Hub` is `Anchored = true` as the static base.
  - `RP_Disc`, `RP_Body`, and `RP_Ring` are welded via `WeldConstraint` into a rigid assembly (`Anchored = false`).
  - Motorized `HingeConstraint` placed at the socket pivot with `WorldAxis = (0, 1, 0)`.
  - Rotates at `1.5 rad/s`.
  - **Friction**: Because rotation is driven by the physics engine, character avatars naturally rotate with the disc.

### B. Vertical Crane Lift (`VerticalLift.luau`)
- **Target Socket**: `SOCKET_CranePlatform` in `Zone2_ChaosFactory.FutureHazardSockets` (`TravelUp = 8`).
- **Target Geometry**: `CP_LiftDeck_Deck`, `CP_LiftDeck_Frame`, `CP_LiftDeck_Under`, `CP_LiftDeck_Edge`, `CP_LiftDeck_Warn`, and `CP_Chain`.
- **Physics Mechanism**:
  - All lift parts are welded to `CP_LiftDeck_Deck` (`Anchored = true`).
  - Server `RunService.Stepped` loop drives vertical displacement at 4 studs/sec with a 2-second dwell at peak and base.
  - Dynamically sets `deck.AssemblyLinearVelocity = Vector3.new(0, ±4, 0)` during transit and `Vector3.zero` while paused.
  - **Grounding**: Setting `AssemblyLinearVelocity` on anchored moving surfaces prevents humanoid floor-snapping glitches.

### C. Disappearing Platforms (`DisappearingPlatform.luau`)
- **Target Socket**: `DisappearingTileGroup` in `Zone3_VoidLunatic.FutureHazards` (`PathFolder = "Route.DisappearingTiles"`).
- **Target Geometry**: `Tile_01` through `Tile_07` (Folders containing `Surface`, `Mark`, `Edge`, `Under`).
- **State Lifecycle**:
  - `Stable` (Initial): Solid, original colors, `CanCollide = true`, `Transparency = 0`.
  - `Warning` (0.85s): Character stepped on platform; turns red (`Color3.fromRGB(255, 60, 60)`).
  - `Vanished` (2.5s): `CanCollide = false`, `Transparency = 1`. Player falls through.
  - `Stable` (Restored): Restores original colors, transparencies, and collision.

---

## 🚀 4. ARCHITECTURAL COMPARISON: CURRENT VS. DETERMINISTIC CLIENT-DRIVEN

| Evaluation Metric | Current Server-Driven Implementation | Future Deterministic Client-Driven (Gold Standard) |
|---|---|---|
| **Character Physics & Friction** | High (using `AssemblyVelocity` & `HingeConstraint`) | Perfect (local `AssemblyVelocity` on character) |
| **Visual Refresh Rate** | Subject to server tick rate & network packet delivery (~20–30 Hz) | Native monitor refresh rate (60Hz / 144Hz / 240Hz) |
| **Server CPU Load** | Scales with active moving parts across zones | **Zero** server movement calculations |
| **Network Lag / Latency Impact** | High-ping players may experience visual jitter | **Zero jitter** (synced via `workspace:GetServerTimeNow()`) |
| **Network Ownership Hazards** | Possible if physics ownership transfers to a laggy player | **Impossible** (parts remain anchored on both client & server) |

---

## 🏆 5. THE INDUSTRY GOLD STANDARD (DETERMINISTIC CLIENT-DRIVEN TIME-SYNC)

### Why Leading Roblox Games Use This Architecture
In premier Roblox obbies and high-fidelity physics games (*Tower of Hell*, *Juke's Towers of Hell*, *Flood Escape 2*), having the server calculate moving platforms or running unanchored constraints causes three severe limitations:
1. **Network Replication Frequency Cap**: Server-side movement only replicates to clients at ~20–30 Hz. On 144Hz+ monitors, platforms visually stutter.
2. **Network Ownership Hand-off Bugs**: When an assembly is unanchored (`Anchored = false`), Roblox dynamically assigns physics network ownership to whichever player is closest. If that player experiences packet loss or high ping, the platform stutters or stops for everyone nearby.
3. **Server Frame Budget**: Running 30+ moving platforms, spinning gears, and elevator threads across 10 zones severely robs the server of CPU budget needed for Guard AI navigation, coin stacking math, and combat hitboxes.

### The Solution: Deterministic Math via `workspace:GetServerTimeNow()`
Instead of simulating motion on the server, the platform remains **`Anchored = true` permanently on both client and server**. The client evaluates its exact 3D transform every frame using a pure mathematical function of time:

```
                                  [ SERVER ]
                                      │
                 1. Starts with parts permanently Anchored = true
                 2. Sockets replicate configuration parameters:
                    { HazardType, Speed, Amplitude, BaseCFrame }
                                      │
                                      ▼
                                  [ CLIENT ]
                     Calculates position purely via math:
             Position = BaseY + math.sin(time) * Amplitude
             Orientation = BaseAngle + time * Speed
                                      │
                                      ▼
               Sets CFrame + AssemblyLinearVelocity / AngularVelocity
                      locally on RenderStepped (120+ FPS)
```

---

### Implementation Blueprint: Mathematical Formulas

#### 1. Rotating Platform (Circular Discs, Giant Gears, Rotating Arms)
- **Mathematical Formula**:
  $$\theta(t) = (\text{elapsed} \times \omega) \pmod{2\pi}$$
- **Client RenderStepped Implementation**:
  ```luau
  local elapsed = workspace:GetServerTimeNow()
  local currentAngle = elapsed * angularSpeed
  discPart.CFrame = pivotCFrame * CFrame.Angles(0, currentAngle, 0)
  discPart.AssemblyAngularVelocity = Vector3.new(0, angularSpeed, 0)
  ```
- **Why this is superior**:
  - Parts remain `Anchored = true` (zero network ownership glitches).
  - Rotates at native screen refresh rate (60 FPS, 144 FPS, 240 FPS).
  - Setting `AssemblyAngularVelocity` on the client applies 100% responsive tangential friction to the local Humanoid with zero latency.

#### 2. Vertical Elevators & Continuous Lifts
- **Mathematical Formula (Smooth Harmonic or Linear Ping-Pong)**:
  $$\Delta y(t) = \frac{\text{TravelUp}}{2} \times \left(1 - \cos\left(\frac{2\pi \times t}{\text{Period}}\right)\right)$$
- **Client RenderStepped Implementation**:
  ```luau
  local elapsed = workspace:GetServerTimeNow()
  local phase = (elapsed % cyclePeriod) / cyclePeriod
  local alpha = 0.5 * (1 - math.cos(phase * 2 * math.pi))
  local currentY = basePosition.Y + (travelUp * alpha)
  
  -- Calculate instantaneous velocity for character grounding:
  local instantaneousVelY = (travelUp * math.pi / cyclePeriod) * math.sin(phase * 2 * math.pi)
  
  liftDeck.CFrame = CFrame.new(basePosition.X, currentY, basePosition.Z) * baseRotation
  liftDeck.AssemblyLinearVelocity = Vector3.new(0, instantaneousVelY, 0)
  ```
- **Why this is superior**:
  - Zero character jitter, zero clipping through elevator decks, and zero false "freefall" triggers.
  - All players see the elevator at the exact same height at the exact same millisecond because `GetServerTimeNow()` is globally synchronized.

---

### Migration Checklist for Production Scaling
When scaling beyond the Zone 2 pilot to all 10 zones:
1. [ ] Keep `HazardService` on the server purely as a metadata validator and socket catalog.
2. [ ] Replicate socket metadata table to a shared client controller (`HazardClientController.luau`).
3. [ ] Keep all physical hazard parts `Anchored = true` in workspace.
4. [ ] Bind active hazards in the local player's current zone to a single `RunService.RenderStepped` loop evaluating the formulas above.
5. [ ] Put non-visible zones to sleep locally (frustum / zone-aware culling) to maintain 120+ FPS on mobile devices.

