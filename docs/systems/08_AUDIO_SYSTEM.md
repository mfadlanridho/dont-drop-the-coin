# Audio System Architecture & Technical Documentation

The **Audio Management System** is a centralized, modular audio architecture designed for `dont-drop-the-coin`. It manages 2D interface sounds, 3D spatial gameplay audio, background music playlist rotation with crossfading, and server-broadcasted audio events.

---

## 1. System Architecture Overview

```
src/
├── shared/
│   ├── Config/
│   │   └── SoundConfig.luau       # Sound asset registry, categories, volume defaults & music playlists
│   ├── Utils/
│   │   └── GameplayAudio.luau     # Core playback utility (2D/3D one-shots & tracked looped audio)
│   └── Remotes.luau               # Includes "PlaySound" remote event
└── client/
    └── Controllers/
        ├── MusicController.client.luau # BGM playlist manager with crossfading & settings listener
        └── AudioController.client.luau # Client remote event listener & UI sound feedback helper
```

---

## 2. Audio Configuration (`SoundConfig.luau`)

Located at [`src/shared/Config/SoundConfig.luau`](../../src/shared/Config/SoundConfig.luau) (replicated as `ReplicatedStorage.Shared.Config.SoundConfig`).

`SoundConfig` defines asset IDs, categories, volume defaults, and background music playlists:

```lua
export type SoundDefinition = {
    Id: string,
    Volume: number,
    Pitch: number?,
}

SoundConfig.Sounds = {
    ButtonClick = { Id = "rbxassetid://6895079853", Volume = 0.5, Pitch = 1.0 },
    ButtonHover = { Id = "rbxassetid://6895079558", Volume = 0.3, Pitch = 1.2 },
    CoinPickup  = { Id = "rbxassetid://6895080031", Volume = 0.6, Pitch = 1.0 },
    DashBump    = { Id = "rbxassetid://9114223179", Volume = 0.8, Pitch = 1.0 },
    RagdollHit  = { Id = "rbxassetid://9114223405", Volume = 0.7, Pitch = 1.0 },
    BankCoins   = { Id = "rbxassetid://6895080275", Volume = 0.8, Pitch = 1.0 },
}
```

### Background Music Playlist Config
```lua
SoundConfig.DefaultPlaylist = {
    { Name = "ChillLobby",   Id = "rbxassetid://1837879082", Volume = 0.3 },
    { Name = "UpbeatAction", Id = "rbxassetid://1837879440", Volume = 0.3 },
}
```

---

## 3. Core API Reference (`GameplayAudio.luau`)

Located at [`src/shared/Utils/GameplayAudio.luau`](../../src/shared/Utils/GameplayAudio.luau) (replicated as `ReplicatedStorage.Shared.Utils.GameplayAudio`).

### `GameplayAudio.playOneShot(soundInput, parent?, volumeOverride?, pitchOverride?): Sound?`
Plays a 2D or 3D one-shot audio effect.
- **2D UI Sound**: Omit `parent` (defaults to `SoundService`).
- **3D Spatial Sound**: Provide a `BasePart` or `Attachment` as `parent`.
- **Automatic Cleanup**: Automatically garbage-collects the sound instance via `Debris` after playback ends.

```lua
local GameplayAudio = require(ReplicatedStorage.Shared.Utils.GameplayAudio)

-- Play 2D UI sound using sound key
GameplayAudio.playOneShot("ButtonClick")

-- Play 3D positional sound attached to a character head
GameplayAudio.playOneShot("CoinPickup", player.Character.Head, 0.8, 1.2)
```

### `GameplayAudio.playLooped(loopId, soundInput, parent?, volumeOverride?, pitchOverride?): Sound?`
Plays a looped sound tracked by a unique string `loopId`. If a loop with the same ID is already playing, it will not duplicate.

```lua
GameplayAudio.playLooped("WindEffect", "rbxassetid://12345678", player.Character.PrimaryPart, 0.4)
```

### `GameplayAudio.stopLooped(loopId, fadeOutTime?)`
Stops and destroys a tracked loop sound. Supports an optional `fadeOutTime` duration using `TweenService`.

```lua
GameplayAudio.stopLooped("WindEffect", 1.5) -- 1.5s fade out
```

---

## 4. Client Controllers

### Music Controller (`MusicController.client.luau`)
Located at [`src/client/Controllers/MusicController.client.luau`](../../src/client/Controllers/MusicController.client.luau).
- Automatically initializes on client startup after a brief delay.
- Randomly shuffles playlist tracks from `SoundConfig.DefaultPlaylist`.
- Performs 3-second crossfades between songs using `TweenService`.
- Listens to `ReplicatedStorage.MusicVolumeChanged` event to scale volume multiplier or mute state seamlessly.

### Audio Controller (`AudioController.client.luau`)
Located at [`src/client/Controllers/AudioController.client.luau`](../../src/client/Controllers/AudioController.client.luau).
- Listens to `Remotes.Get("PlaySound").OnClientEvent` for server-requested sound triggers.
- Exports `AudioController.playUI(soundKey)` helper function for UI components.

---

## 5. Server-to-Client Remote Triggers (`PlaySound`)

Server scripts can trigger sound effects on specific clients or broadcast audio to all clients via `Remotes.Get("PlaySound")`:

```lua
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlaySoundRemote = Remotes.Get("PlaySound")

-- Trigger audio on a single client
PlaySoundRemote:FireClient(player, "CoinPickup", player.Character.Head, 0.6, 1.1)

-- Broadcast audio to all clients (e.g., Bank Cashout explosion sound)
PlaySoundRemote:FireAllClients("BankCoins", bankPadPart, 1.0, 1.0)
```

---

## 6. Integration Guide & Best Practices

1. **Adding New Audio Assets**: Register new sound keys in `SoundConfig.Sounds` with appropriate default volumes and optional pitch parameters.
2. **Positional Spatial Audio**: Always pass the character's `PrimaryPart` or `Head` as the `parent` parameter to `GameplayAudio.playOneShot()` when an audio event occurs in the 3D world.
3. **UI Feedback**: Call `AudioController.playUI("ButtonClick")` inside `Activated` or `MouseButton1Click` callbacks for UI buttons.
