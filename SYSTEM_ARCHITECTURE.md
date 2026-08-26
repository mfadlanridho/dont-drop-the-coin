# 📐 DON'T DROP THE COIN! — SYSTEM ARCHITECTURE & TECHNICAL DOCUMENTATION

This document provides a comprehensive technical overview of the system architecture, data flow, server-client networking, and state machine diagrams for **Don't Drop The Coin!**.

---

## 🏗️ 1. OVERALL SYSTEM ARCHITECTURE

```mermaid
graph TD
    subgraph CLIENT ["Client (StarterPlayerScripts & StarterGui)"]
        InputCtrl["InputController (PC Keybinds / Mobile Touch Buttons)"]
        StackVis["StackVisualizer (Client-side Sway Lerp & Visual Mesh)"]
        FXCtrl["FXController (Particle Emitters, SFX Matrix, Camera Shake)"]
        HUD["HUD & UI Tweens (Wallet Display, Cooldown Timers)"]
    end

    subgraph REMOTES ["ReplicatedStorage (Remotes & Shared Modules)"]
        RemoteEvents["RemoteEvents (PickupCoin, DashBump, BankCoins, TriggerRagdoll)"]
        Config["Config Module (Data Defaults, Zone Multipliers, Timers)"]
        SoundMgr["SoundManager Module (Pitch Scaling Audio Matrix)"]
    end

    subgraph SERVER ["Server (ServerScriptService)"]
        DSM["DataStoreManager (Session Cache, DataStore Save/Load)"]
        CoinSpawn["CoinSpawner (Zone Spawners & Node Respawns)"]
        StackServ["StackServer (Stack Mass, Height & Physics Sync)"]
        CombatServ["CombatServer (Hitbox Raycasts, Impulse & Cooldowns)"]
        BankServ["BankServer (Safe Zone Detection & Cashout Math)"]
    end

    InputCtrl -->|Fires Remote| RemoteEvents
    RemoteEvents -->|Validates & Processes| CombatServ
    RemoteEvents -->|Validates & Processes| BankServ
    CoinSpawn -->|Touch Verified| StackServ
    StackServ -->|Updates Stack Data| DSM
    StackServ -->|Syncs Attachment| StackVis
    CombatServ -->|Triggers Hit| FXCtrl
    BankServ -->|Saves Currency| DSM
    DSM -->|Updates Wallet UI| HUD
```

---

## 💾 2. DATASTORE & SESSION DATA FLOW

```mermaid
sequenceDiagram
    autonumber
    actor Player
    participant Client as Client Script
    participant Server as ServerScriptService
    participant DSM as DataStoreManager
    participant DS as Roblox DataStore API

    Note over Player, DS: PLAYER JOINING PHASE
    Player->>Server: Connects to Game
    Server->>DSM: PlayerAdded Triggered
    DSM->>DS: GetAsync("Player_" .. UserId)
    DS-->>DSM: Returns Saved Profile Data
    DSM->>DSM: Create In-Memory Session Cache
    DSM-->>Client: Replicate Initial Wallet Balance & Owned Passes

    Note over Player, DS: IN-GAME MUTATION PHASE
    Player->>Client: Collects Coin / Banks Stack
    Client->>Server: FireServer Remote Request
    Server->>DSM: UpdateSessionCache(player, newCoins)
    DSM-->>Client: Replicate Updated Wallet Value

    Note over Player, DS: PLAYER LEAVING / AUTO-SAVE PHASE
    Player->>Server: Disconnects / Server Shutdown
    Server->>DSM: PlayerRemoving / BindToClose Triggered
    DSM->>DS: SetAsync / UpdateAsync("Player_" .. UserId, SessionCache)
    DS-->>DSM: Save Confirmed
```

---

## 🌀 3. CORE GAMEPLAY STATE MACHINE

```mermaid
stateDiagram-v2
    [*] --> SafeZoneInLobby: Player Spawns in Ground Lobby

    state SafeZoneInLobby {
        [*] --> IdleInBank
        IdleInBank --> BankCoins: Step on Bank Pad (Cash = Stack * Multiplier)
        BankCoins --> IdleInBank: Wallet Updated & Stack Cleared
    }

    SafeZoneInLobby --> ClimbingTower: Step Out of Safe Zone

    state ClimbingTower {
        [*] --> WalkingNormal
        WalkingNormal --> CoinCollected: Touch Floating Coin Node
        CoinCollected --> StackWobbling: Increment Stack & Increase Head Mass / Sway
        StackWobbling --> WalkingNormal: Stack Height Updated

        StackWobbling --> StruckByBumpOrTrap: Hit by Player Dash / Piston / AI Monster
    }

    StruckByBumpOrTrap --> PhysicsRagdoll: Humanoid PlatformStand = true (2.5s)

    state PhysicsRagdoll {
        [*] --> DetachStack
        DetachStack --> ScatterCoins: Explode Unanchored Coins in 360 Arc
        ScatterCoins --> RagdollRecovery: Wait 2.5 Seconds
    }

    RagdollRecovery --> ClimbingTower: Stand Up (Stack Reset to 0)
    ClimbingTower --> SafeZoneInLobby: Walk/Jump Back Down to Ground Floor
```

---

## 📡 4. SERVER-CLIENT NETWORK CONTRACT (REMOTES)

| Remote Name | Type | Direction | Description |
| --- | --- | --- | --- |
| `PickupCoin` | `RemoteEvent` | Client $\rightarrow$ Server | Fired when client touches a floating coin node. Server validates distance & updates stack. |
| `DashBump` | `RemoteEvent` | Client $\rightarrow$ Server | Fired when player presses `E` / Touch Button. Server verifies cooldown & performs hitbox check. |
| `BankCoins` | `RemoteEvent` | Client $\rightarrow$ Server | Fired when player steps on Bank Pad. Server calculates multiplier & saves to DataStore. |
| `UpdateHUD` | `RemoteEvent` | Server $\rightarrow$ Client | Sent to client to update wallet counter, stack height meter, and UI bounce animations. |
| `PlayVFX` | `RemoteEvent` | Server $\rightarrow$ Client | Replicates sound pitch effects, particle sparkles, and camera shake to nearby clients. |
| `PlaySound` | `RemoteEvent` | Server $\rightarrow$ Client | Broadcasts 2D UI or 3D spatial sound triggers to target clients or all clients. |
