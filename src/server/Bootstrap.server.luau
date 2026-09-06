local Players = game:GetService("Players")

local Services = script.Parent:WaitForChild("Services")
local DataStoreManager = require(Services:WaitForChild("DataStoreManager"))

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		DataStoreManager.LoadPlayer(player)
	end)
end

Players.PlayerAdded:Connect(function(player)
	local success, result = DataStoreManager.LoadPlayer(player)

	if not success then
		warn("[Bootstrap] Failed to load " .. player.Name .. ": " .. tostring(result))
	end
end)