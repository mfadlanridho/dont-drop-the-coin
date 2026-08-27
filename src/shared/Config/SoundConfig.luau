--!strict
--[[
    SoundConfig.luau
    Central registry for game audio IDs, playlists, volume defaults, and categories.
    Location: src/shared/Config/SoundConfig.luau
--]]

export type SoundDefinition = {
	Id: string,
	Volume: number,
	Pitch: number?,
}

local SoundConfig = {}

-- Audio Categories
SoundConfig.Categories = {
	SFX = "SFX",
	Music = "Music",
	UI = "UI",
}

-- Registry of Sound Definitions (Replace Asset IDs with custom audio when ready)
SoundConfig.Sounds = {
	-- UI Sounds
	ButtonClick = {
		Id = "rbxassetid://6895079853",
		Volume = 0.5,
		Pitch = 1.0,
	} :: SoundDefinition,
	ButtonHover = {
		Id = "rbxassetid://139719503904449",
		Volume = 0.3,
		Pitch = 1.2,
	} :: SoundDefinition,

	-- Gameplay Sounds
	CoinPickup = {
		Id = "rbxassetid://135483737426662",
		Volume = 0.6,
		Pitch = 1.0,
	} :: SoundDefinition,
	DashBump = {
		Id = "rbxassetid://9120729973",
		Volume = 0.8,
		Pitch = 1.0,
	} :: SoundDefinition,
	RagdollHit = {
		Id = "rbxassetid://9113525391",
		Volume = 0.7,
		Pitch = 1.0,
	} :: SoundDefinition,
	BankCoins = {
		Id = "rbxassetid://9113581128",
		Volume = 0.8,
		Pitch = 1.0,
	} :: SoundDefinition,
}

-- Default Playlist for Background Music (Asset IDs)
SoundConfig.DefaultPlaylist = {
	{
		Name = "ChillLobby",
		Id = "rbxassetid://1837879082",
		Volume = 0.3,
	},
	{
		Name = "UpbeatAction",
		Id = "rbxassetid://1837768143",
		Volume = 0.3,
	},
}

-- Default Volume Multipliers
SoundConfig.DefaultMasterVolume = 1.0
SoundConfig.DefaultSFXVolume = 1.0
SoundConfig.DefaultMusicVolume = 0.5

return SoundConfig
