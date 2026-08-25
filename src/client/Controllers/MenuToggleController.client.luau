-- MenuToggleController Client Script
-- Automatically binds HUD buttons to toggle target frames via OpenFrame
-- Supports PlayerGui.Menus.Toggles, PlayerGui.ScreenGui.Toggles, and custom layouts
-- Dynamically updates ScrollingFrame CanvasSize for smooth scrolling
-- Place in: src/client/Controllers/MenuToggleController.client.luau -> StarterPlayer.StarterPlayerScripts.Client.Controllers.MenuToggleController

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIFolder = SharedFolder:WaitForChild("UI")
local ButtonFunctionality = require(UIFolder:WaitForChild("ButtonFunctionality"))
local OpenFrame = require(UIFolder:WaitForChild("OpenFrame"))

local function findPrimaryButton(container)
	if container == nil or not container:IsA("GuiObject") then
		return nil
	end

	local imageButton = container:FindFirstChild("ImageButton")
	if imageButton ~= nil and imageButton:IsA("GuiButton") then
		return imageButton
	end

	local textButton = container:FindFirstChild("TextButton")
	if textButton ~= nil and textButton:IsA("GuiButton") then
		return textButton
	end

	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			return descendant
		end
	end

	return nil
end

local function findScale(button)
	if button == nil then
		return nil
	end

	local buttonScale = button:FindFirstChildOfClass("UIScale")
	if buttonScale ~= nil then
		return buttonScale
	end

	local parent = button.Parent
	if parent ~= nil then
		return parent:FindFirstChildOfClass("UIScale")
	end

	return nil
end

local function setupAutoScrollingCanvas(scrollingFrame)
	if not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame") then return end

	local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout") or scrollingFrame:FindFirstChildOfClass("UIGridLayout")
	if not layout then return end

	local function updateCanvas()
		task.wait()
		scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 40)
		scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
		scrollingFrame.Active = true
		scrollingFrame.ScrollBarThickness = 8
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
	scrollingFrame.ChildAdded:Connect(updateCanvas)
	scrollingFrame.ChildRemoved:Connect(updateCanvas)
	updateCanvas()
end

local function bindToggle(toggleFrame)
	if toggleFrame:GetAttribute("_toggle_bound") then
		return
	end

	local targetName = toggleFrame:GetAttribute("TargetTab")
	if type(targetName) ~= "string" or targetName == "" then
		targetName = toggleFrame.Name
	end

	local button = findPrimaryButton(toggleFrame) or (toggleFrame:IsA("GuiButton") and toggleFrame or nil)
	if button == nil then
		return
	end

	toggleFrame:SetAttribute("_toggle_bound", true)

	ButtonFunctionality.SetupButton(button, findScale(button), {
		onClickCallback = function()
			OpenFrame.ToggleFrame(targetName)
		end,
	})
end

local function setupMobileTouchScaling(togglesFolder, parentGui)
	local togglesUIScale = togglesFolder:FindFirstChildOfClass("UIScale")
	if not togglesUIScale then
		togglesUIScale = Instance.new("UIScale")
		togglesUIScale.Name = "TogglesScale"
		togglesUIScale.Parent = togglesFolder
	end

	local function updateScale()
		local size = parentGui and parentGui:IsA("GuiObject") and parentGui.AbsoluteSize or workspace.CurrentCamera.ViewportSize
		local scale = 1.0

		if UserInputService.TouchEnabled then
			scale = 1.5 -- Scale up by 50% on mobile touch screens
		elseif size.Y < 500 then
			scale = 1.25 -- Fallback for very short screens
		end

		togglesUIScale.Scale = scale
	end

	if parentGui and parentGui:IsA("GuiObject") then
		parentGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	updateScale()
end

local function scanAndBindToggles(togglesFolder, parentGui)
	if not togglesFolder then return end

	setupMobileTouchScaling(togglesFolder, parentGui)

	for _, child in ipairs(togglesFolder:GetChildren()) do
		if child:IsA("GuiObject") then
			bindToggle(child)
		end
	end

	togglesFolder.ChildAdded:Connect(function(child)
		if child:IsA("GuiObject") then
			bindToggle(child)
		end
	end)
end

local function setupToggleListeners()
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Connect ScrollingFrame canvas auto-scaling across all tabs
	for _, desc in ipairs(playerGui:GetDescendants()) do
		if desc:IsA("ScrollingFrame") then
			setupAutoScrollingCanvas(desc)
		end
	end
	playerGui.DescendantAdded:Connect(function(desc)
		if desc:IsA("ScrollingFrame") then
			setupAutoScrollingCanvas(desc)
		end
	end)

	-- 1. Check PlayerGui.Menus.Toggles
	local menusGui = playerGui:WaitForChild("Menus", 5)
	if menusGui then
		local togglesFolder = menusGui:FindFirstChild("Toggles") or menusGui:WaitForChild("Toggles", 5)
		if togglesFolder then
			scanAndBindToggles(togglesFolder, menusGui)
			return
		end
	end

	-- 2. Fallback: Check PlayerGui.ScreenGui.Toggles
	local screenGui = playerGui:FindFirstChild("ScreenGui")
	if screenGui then
		local togglesFolder = screenGui:FindFirstChild("Toggles")
		if togglesFolder then
			scanAndBindToggles(togglesFolder, screenGui)
			return
		end
	end

	-- 3. Universal Fallback: Wait for any folder/frame named "Toggles"
	task.spawn(function()
		local toggles = playerGui:WaitForChild("Toggles", 10)
		if toggles then
			scanAndBindToggles(toggles, toggles.Parent)
		end
	end)
end

task.spawn(setupToggleListeners)
