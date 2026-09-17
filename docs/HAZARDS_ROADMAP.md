# 📋 HAZARD ROADMAP & BUILDER INTENT SPECIFICATION

This tracker catalogs every environmental hazard, obstacle, and mechanical socket planned by the level designer across all 10 zones in **Don't Drop The Coin!**. It outlines implementation status, attributes, physical mechanisms, and recommended development priorities.

---

## 📊 OVERALL STATUS SUMMARY

| Zone | Name | Theme | Sockets / Planned | Implemented | Status |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **Zone 1** | Sunny Start | Grassy Tutorial | 0 | 0 | 🟢 Safe Zone (No Hazards) |
| **Zone 2** | Chaos Factory | Industrial / Machinery | 3 | 2 | 🟡 Pilot Ready (Conveyor Remaining) |
| **Zone 3** | Void Lunatic | Sci-Fi / Glitch Void | 4 | 1 | 🟡 Pilot Ready (3 Void Hazards Remaining) |
| **Zone 4** | Mechanical Works | Heavy Clockwork | 4 | 0 | ⚪ Backlog |
| **Zone 5** | Neon City | Cyberpunk High-Tech | 4 types (10 parts) | 0 | ⚪ Backlog |
| **Zone 6** | Aquatica | Underwater Sunken Ruins | 6 | 0 | ⚪ Backlog |
| **Zone 7** | Temple of Ascension | Ancient Stone Ruins | 7 | 0 | ⚪ Backlog |
| **Zone 8** | Sky Kingdom | Cloud & Celestial | 7 | 0 | ⚪ Backlog |
| **Zone 9** | Mystic Realm | Arcane Magic | 3 | 0 | ⚪ Backlog |
| **Zone 10** | Hellfire | Magma & Fortress | 7 | 0 | ⚪ Backlog |
| **Total** | | | **45 Sockets** | **3 Live** | **3 Live / 42 Planned** |

---

## 🗺️ DETAILED ZONE-BY-ZONE HAZARD TRACKER

### Zone 1: Sunny Start (Tutorial)
*Design Intent: Safe onboarding zone. No environmental hazards.*
- *(None planned)*

---

### Zone 2: Chaos Factory (Industrial Mechanics)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Rotating Platform** | `SOCKET_RotatingPlatform` | `Diameter: 16`<br>`TopY: 113.5` | Motorized `HingeConstraint` rotating `RP_Disc`, `RP_Body`, `RP_Ring` around `RP_Hub` at 1.5 rad/s. | ✅ **LIVE** |
| **Vertical Lift** | `SOCKET_CranePlatform` | `TravelUp: 8` | Kinematic crane carriage lift cycling $+8$ studs vertically with `AssemblyLinearVelocity`. | ✅ **LIVE** |
| **Conveyor Belt** | `SOCKET_Conveyor` | `Heading0: 325.5`<br>`Heading1: 360` | Directional surface conveyor applying `AssemblyLinearVelocity` along factory floor line. | ⏳ **Next** |

---

### Zone 3: Void Lunatic (Glitch & Void)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Disappearing Tiles** | `DisappearingTileGroup` | `TileCount: 7`<br>`PathFolder: Route.DisappearingTiles` | 7 floor tiles (`Tile_01`–`Tile_07`) that flash red (0.85s), vanish & drop collision (2.5s), and respawn. | ✅ **LIVE** |
| **Glitch Pulse Bridge** | `GlitchPulse_Bridge` | `HazardType: GlitchPulse_Bridge` | Periodic energetic beam or barrier across bridge dealing stack knockback on pulse. | ⚪ Backlog |
| **Ascent Void Platform** | `MovingVoidPlatform_Ascent`| `HazardType: MovingVoidPlatform_Ascent` | Floating platform oscillating vertically over bottomless void drop. | ⚪ Backlog |
| **Glitch Drone Patrol** | `GlitchDroneRoam_Upper` | `HazardType: GlitchDroneRoam_Upper` | Roaming airborne drone patrolling the upper sector. | ⚪ Backlog |

---

### Zone 4: Mechanical Works (Clockwork & Gears)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Giant Gear** | `SOCKET_GiantGear` | `Diameter: 18`<br>`HazardType: RotatingGear` | Massive 18-stud vertical spinning cogwheel obstructing the path. | ⚪ Backlog |
| **Rotating Sweep Arms**| `SOCKET_RotatingArms` | `HubY: 225`<br>`HazardType: RotatingArms` | Horizontal beam arms sweeping across platform height; must jump over. | ✅ **LIVE** |
| **Moving Platforms** | `SOCKET_MovingPlatforms` | `HazardType: MovingPlatforms` | Horizontally translating platform bridges across machinery chasm. | ⚪ Backlog |
| **Vertical Carriages** | `SOCKET_VerticalCarriages` | `HazardType: VerticalCarriages` | Counterbalanced vertical lift carriage pair. | ⚪ Backlog |

---

### Zone 5: Neon City (Cyberpunk High-Tech)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Laser Barrier (x2)** | `SOCKET_LaserBarrier` | `Span: 10`<br>`HazardType: LaserBarrier` | Corridors with pulsing or sweeping laser tripwires causing ragdoll/coin drops. | ⚪ Backlog |
| **Elevator Platforms** | `SOCKET_ElevatorPlatforms`| `HazardType: ElevatorPlatforms` | High-speed glass/neon vertical elevator shaft. | ⚪ Backlog |
| **Moving Platforms** | `SOCKET_MovingPlatforms` | `HazardType: MovingPlatforms` | Floating neon transport pads moving between skyscrapers. | ⚪ Backlog |
| **Monorail Carriages** | `C1/C3_Carriage_Yoke/Shoe`| *(Geometry Frames)* | Hanging overhead carriages moving along rails. | ⚪ Backlog |

---

### Zone 6: Aquatica (Sunken Ruins & Water)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Bubble Elevator (x2)**| `SOCKET_BubbleElevator_230/240` | `HazardType: BubbleElevator` | Vertical current column applying buoyancy impulse lifting players upward. | ⚪ Backlog |
| **Water Current** | `SOCKET_WaterCurrent` | `HazardType: WaterCurrent` | Flowing rapids pushing player and loose coins downstream toward edge. | ⚪ Backlog |
| **Rotating Ruins (x2)** | `SOCKET_RotatingRuin_1/2`| `HazardType: RotatingRuin` | Submerged stone ruin blocks tumbling or revolving in water. | ⚪ Backlog |
| **Rising Platforms** | `SOCKET_RisingPlatforms` | `HazardType: RisingPlatforms` | Tidal platforms cyclically emerging and submerging underwater. | ⚪ Backlog |

---

### Zone 7: Temple of Ascension (Ancient Traps)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Rotating Pillars (x3)**| `SOCKET_RotatingPillar_1/2/3` | `HazardType: RotatingPillar` | Three narrow spinning stone pillars requiring precise parkour timing. | ⚪ Backlog |
| **Moving Wall Pushers (x2)**| `SOCKET_MovingWall_1/2` | `HazardType: MovingWall` | Giant stone blocks jutting out from walls to shove players off ledge. | ⚪ Backlog |
| **Crumbling Platforms** | `SOCKET_CrumblingPlatforms` | `HazardType: CrumblingPlatforms` | Fragile ancient tiles that crack and collapse permanently until reset. | ⚪ Backlog |
| **Lift Platforms** | `SOCKET_LiftPlatforms` | `HazardType: LiftPlatforms` | Counterweighted stone elevator platforms. | ⚪ Backlog |

---

### Zone 8: Sky Kingdom (Clouds & Celestial Wind)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Drifting Clouds (x3)** | `CL1/CL2/CL3_Cloud_Socket` | `HazardType: MovingCloud` | Floating cloud platforms on continuous waypoint patrol between sky islands. | ⚪ Backlog |
| **Wind Currents (x2)** | `SOCKET_WindCurrent_1/2`| `HazardType: WindCurrent` | Crosswind air blasts pushing players sideways off narrow sky bridges. | ⚪ Backlog |
| **Rotating Sky Ruins (x2)**| `SOCKET_RotatingRuin_1/2` | `HazardType: RotatingSkyRuin` | Floating celestial ruins rotating mid-air. | ⚪ Backlog |

---

### Zone 9: Mystic Realm (Arcane Teleportation)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Teleport Rings (Pair)** | `SOCKET_TeleportRing_1/2` | `Pair: 1`, `Pair: 2`<br>`HazardType: TeleportRing` | Paired portal rings teleporting players instantly across a chasm with visual VFX. | ⚪ Backlog |
| **Moving Magic Bridge** | `SOCKET_MovingMagicBridge` | `HazardType: MovingMagicBridge` | Dynamic arcane energy bridge weaving or expanding/contracting. | ⚪ Backlog |

---

### Zone 10: Hellfire (Volcanic Fortress)
| Hazard Name | Socket / Anchor | Attributes | Mechanism & Description | Status |
| :--- | :--- | :--- | :--- | :---: |
| **Swinging Chain Bridge**| `SOCKET_ChainBridge` | `HazardType: SwingingChainBridge` | Physics-simulated hanging chain bridge swinging over lava chasm. | ⚪ Backlog |
| **Moving Fortress Blocks (x3)**| `SOCKET_MovingFortress_1/2/3` | `HazardType: MovingFortressBlock` | Heavy battering ram blocks hammering across fortress catwalks. | ⚪ Backlog |
| **Rising Magma Pillars (x3)**| `SOCKET_RisingPlatform_1/2/3` | `HazardType: RisingPlatform` | Basalt pillars rising out of molten lava and submerging periodically. | ⚪ Backlog |

---

## 🎯 RECOMMENDED STEP-BY-STEP IMPLEMENTATION ROADMAP

### **Step 1 (Recommended First): Complete Zone 2 (`SOCKET_Conveyor`)**
- **Why do this first?**
  1. Zone 2 is already 66% done (Rotating Platform and Vertical Lift are live).
  2. Adding `Conveyor.luau` makes **Zone 2 the first 100% complete hazard zone** in the game.
  3. Conveyors use simple physics (`AssemblyLinearVelocity` directed along `Heading0`/`Heading1`), which naturally pushes both players and loose dropped coins!

### **Step 2: Finish Zone 3 Void Mechanics**
- Complete `GlitchPulse_Bridge` and `MovingVoidPlatform_Ascent` so Zone 3 reaches 100% completion alongside Disappearing Tiles.

### **Step 3: Zone 4 Heavy Machinery (`SOCKET_GiantGear` & `SOCKET_RotatingArms`)**
- Leverage the rotation logic already built in `RotatingPlatform` to animate the giant 18-stud gear and sweeping jump-over arms.

### **Step 4: Zone 5 Laser Barriers**
- Implement `LaserBarrier.luau` with raycast tripwires, combat stack-drop integration, and visual beams.
