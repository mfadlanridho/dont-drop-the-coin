-- Server Settings Service
-- Handles remote settings updates from clients and persists values in player data
-- Place in: src/server/Services/SettingsService.luau -> ServerScriptService.Server.Services.SettingsService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local updateVolumeSettingRemote = ReplicatedStorage:FindFirstChild("UpdateVolumeSetting")
if not updateVolumeSettingRemote then
	updateVolumeSettingRemote = Instance.new("RemoteEvent")
	updateVolumeSettingRemote.Name = "UpdateVolumeSetting"
	updateVolumeSettingRemote.Parent = ReplicatedStorage
end

local function ensurePlayerSettingsData(player: Player)
	local otherData = player:FindFirstChild("OtherData")
	if not otherData then
		otherData = Instance.new("Folder")
		otherData.Name = "OtherData"
		otherData.Parent = player
	end

	local musicVolume = otherData:FindFirstChild("MusicVolume")
	if not musicVolume then
		musicVolume = Instance.new("NumberValue")
		musicVolume.Name = "MusicVolume"
		musicVolume.Value = 0.3
		musicVolume.Parent = otherData
	end

	return musicVolume
end

local SettingsService = {}

function SettingsService.Init()
	Players.PlayerAdded:Connect(function(player)
		ensurePlayerSettingsData(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		ensurePlayerSettingsData(player)
	end

	updateVolumeSettingRemote.OnServerEvent:Connect(function(player: Player, value: any)
		if typeof(value) == "number" then
			local clamped = math.clamp(value, 0, 1)
			local snapped = math.round(clamped * 10) / 10
			local musicVolume = ensurePlayerSettingsData(player)
			musicVolume.Value = snapped
		end
	end)
	
	print("[SettingsService] Server settings service initialized.")
end

return SettingsService
