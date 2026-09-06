--!strict
--[[
    HUDController.luau
    Syncs player stats to StarterGui.MainHUD.PermaCash.
    Location: src/client/Controllers/HUDController.luau
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HUDController = {}

-- Configurable: Set to "Stack" for current unbanked coins, or "Coins" for permanent banked cash
local TARGET_STAT = "Stack"

function HUDController.Init()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local leaderstats = LocalPlayer:WaitForChild("leaderstats", 15) :: Folder?
	if not leaderstats then return end

	local statVal = leaderstats:WaitForChild(TARGET_STAT, 10) :: NumberValue?
	if not statVal then return end

	local function bindLabel()
		local mainHud = playerGui:WaitForChild("MainHUD", 10) :: ScreenGui?
		if not mainHud then return end

		local permaCash = mainHud:FindFirstChild("PermaCash", true)
		if not permaCash then
			local container = mainHud:WaitForChild("PermaCashContainer", 5)
			permaCash = container and container:WaitForChild("PermaCash", 5)
		end
		if not permaCash then return end

		local label = permaCash:WaitForChild("TextLabel", 5) :: TextLabel?
		if not label then return end

		local function update()
			label.Text = tostring(statVal.Value)
		end

		statVal.Changed:Connect(update)
		update()
	end

	task.spawn(bindLabel)

	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "MainHUD" then
			task.spawn(bindLabel)
		end
	end)
end

return HUDController
