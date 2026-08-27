--!nonstrict
--[[
    NotificationController.client.luau
    Client controller that listens to SendNotification RemoteEvent and invokes NotificationService.
    Location: src/client/Controllers/NotificationController.client.luau (Syncs to StarterPlayerScripts.Client.Controllers.NotificationController)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local UI = Shared:WaitForChild("UI")
local NotificationService = require(UI:WaitForChild("NotificationService"))

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local SendNotification = RemotesFolder:WaitForChild("SendNotification") :: RemoteEvent

SendNotification.OnClientEvent:Connect(function(payload: any, arg2: any, arg3: any)
	if type(payload) == "table" then
		local title = type(payload.Title) == "string" and payload.Title or "ANNOUNCEMENT"
		local description = type(payload.Description) == "string" and payload.Description or ""
		local duration = type(payload.Duration) == "number" and payload.Duration or 5
		local soundName = type(payload.SoundName) == "string" and payload.SoundName or "Open_UI"

		local color = Color3.fromRGB(255, 215, 0)
		if payload.Color and typeof(payload.Color) == "Color3" then
			color = payload.Color
		end

		NotificationService.showBanner({
			Title = title,
			Description = description,
			Duration = duration,
			Color = color,
			SoundName = soundName,
		})
	elseif type(payload) == "string" then
		NotificationService.showBanner({
			Title = payload,
			Description = type(arg2) == "string" and arg2 or "",
			Duration = type(arg3) == "number" and arg3 or 5,
		})
	end
end)
