-- SubTabManager Module
-- Manages sub-tab switching within modal menus (e.g. Shop categories, Settings pages)
-- Place in: src/shared/UI/SubTabManager.luau -> ReplicatedStorage.Shared.UI.SubTabManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local UIFolder = SharedFolder:WaitForChild("UI")
local ButtonFunctionality = require(UIFolder:WaitForChild("ButtonFunctionality"))

local SubTabManager = {}
SubTabManager.__index = SubTabManager

function SubTabManager.new(config)
	local self = setmetatable({}, SubTabManager)
	
	self.buttonsFolder = config.buttonsFolder -- Folder/Frame containing tab buttons
	self.contentFolder = config.contentFolder -- Folder/Frame containing tab content frames
	self.activeColor = config.activeColor or Color3.fromRGB(255, 255, 255)
	self.inactiveColor = config.inactiveColor or Color3.fromRGB(180, 180, 180)
	self.activeTransparency = config.activeTransparency or 0
	self.inactiveTransparency = config.inactiveTransparency or 0.3
	self.currentTab = nil
	self.tabs = {}

	self:_init(config.defaultTab)
	return self
end

function SubTabManager:_init(defaultTabName)
	if not self.buttonsFolder or not self.contentFolder then
		warn("SubTabManager: Missing buttonsFolder or contentFolder")
		return
	end

	for _, button in ipairs(self.buttonsFolder:GetChildren()) do
		if button:IsA("GuiObject") then
			local tabName = button:GetAttribute("TargetTab") or button.Name
			local contentFrame = self.contentFolder:FindFirstChild(tabName)

			if contentFrame and contentFrame:IsA("GuiObject") then
				self.tabs[tabName] = {
					button = button,
					frame = contentFrame,
				}

				ButtonFunctionality.SetupButton(button, nil, {
					onClickCallback = function()
						self:SelectTab(tabName)
					end,
				})
			end
		end
	end

	if defaultTabName and self.tabs[defaultTabName] then
		self:SelectTab(defaultTabName)
	else
		-- Select first available tab if default not specified
		local firstTab = next(self.tabs)
		if firstTab then
			self:SelectTab(firstTab)
		end
	end
end

function SubTabManager:SelectTab(tabName)
	local targetData = self.tabs[tabName]
	if not targetData then
		warn("SubTabManager: Tab not found:", tabName)
		return
	end

	if self.currentTab == tabName then
		return
	end

	self.currentTab = tabName

	for name, data in pairs(self.tabs) do
		local isSelected = (name == tabName)
		data.frame.Visible = isSelected

		-- Update button visual state
		local btn = data.button
		if btn:IsA("TextButton") or btn:IsA("TextLabel") then
			btn.TextColor3 = isSelected and self.activeColor or self.inactiveColor
			btn.TextTransparency = isSelected and self.activeTransparency or self.inactiveTransparency
		elseif btn:IsA("ImageButton") or btn:IsA("ImageLabel") then
			btn.ImageColor3 = isSelected and self.activeColor or self.inactiveColor
			btn.ImageTransparency = isSelected and self.activeTransparency or self.inactiveTransparency
		end

		local bg = btn:FindFirstChild("Background") or btn
		if bg:IsA("GuiObject") and bg ~= btn then
			bg.BackgroundTransparency = isSelected and self.activeTransparency or self.inactiveTransparency
		end
	end
end

return SubTabManager
