-- UIBuilder Module
-- Programmatically constructs the GDD UI structure (including Shop Modal) in Roblox Studio
-- Place in: src/shared/UI/UIBuilder.luau -> ReplicatedStorage.Shared.UI.UIBuilder

local StarterGui = game:GetService("StarterGui")

local UIBuilder = {}

local function getOrCreate(parent, name, className)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local newInst = Instance.new(className)
	newInst.Name = name
	newInst.Parent = parent
	return newInst
end

function UIBuilder.BuildAll(targetRoot)
	local parentRoot = targetRoot or StarterGui
	-- 1. Create HUDGui (ScreenGui, DisplayOrder = 1)
	local hudGui = getOrCreate(parentRoot, "HUDGui", "ScreenGui")
	hudGui.DisplayOrder = 1
	hudGui.ResetOnSpawn = false
	hudGui.IgnoreGuiInset = true

	local walletFrame = getOrCreate(hudGui, "WalletFrame", "Frame")
	walletFrame.AnchorPoint = Vector2.new(0, 0)
	walletFrame.Position = UDim2.new(0, 20, 0, 20)
	walletFrame.Size = UDim2.new(0, 240, 0, 80)
	walletFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	walletFrame.BackgroundTransparency = 0.25

	local walletCorner = getOrCreate(walletFrame, "UICorner", "UICorner")
	walletCorner.CornerRadius = UDim.new(0, 12)

	local walletStroke = getOrCreate(walletFrame, "UIStroke", "UIStroke")
	walletStroke.Color = Color3.fromRGB(255, 215, 0)
	walletStroke.Thickness = 2

	local coinsLabel = getOrCreate(walletFrame, "CoinsLabel", "TextLabel")
	coinsLabel.Position = UDim2.new(0, 15, 0, 10)
	coinsLabel.Size = UDim2.new(1, -30, 0, 30)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "COINS: 0"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	coinsLabel.TextSize = 20
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left

	local bankedLabel = getOrCreate(walletFrame, "BankedLabel", "TextLabel")
	bankedLabel.Position = UDim2.new(0, 15, 0, 40)
	bankedLabel.Size = UDim2.new(1, -30, 0, 30)
	bankedLabel.BackgroundTransparency = 1
	bankedLabel.Text = "BANKED: $0"
	bankedLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	bankedLabel.TextSize = 18
	bankedLabel.Font = Enum.Font.GothamMedium
	bankedLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- DashBumpButton
	local dashButton = getOrCreate(hudGui, "DashBumpButton", "ImageButton")
	dashButton.AnchorPoint = Vector2.new(1, 1)
	dashButton.Position = UDim2.new(1, -20, 1, -20)
	dashButton.Size = UDim2.new(0, 90, 0, 90)
	dashButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
	dashButton.BackgroundTransparency = 0.2

	local dashCorner = getOrCreate(dashButton, "UICorner", "UICorner")
	dashCorner.CornerRadius = UDim.new(1, 0)

	local dashText = getOrCreate(dashButton, "Text", "TextLabel")
	dashText.Size = UDim2.new(1, 0, 1, 0)
	dashText.BackgroundTransparency = 1
	dashText.Text = "DASH BUMP\n[E]"
	dashText.TextColor3 = Color3.fromRGB(255, 255, 255)
	dashText.TextSize = 14
	dashText.Font = Enum.Font.GothamBold

	-- 2. Menus & Toggles (ScreenGui, DisplayOrder = 5)
	local menusGui = getOrCreate(parentRoot, "Menus", "ScreenGui")
	menusGui.DisplayOrder = 5
	menusGui.ResetOnSpawn = false
	menusGui.IgnoreGuiInset = true

	local toggles = getOrCreate(menusGui, "Toggles", "Frame")
	toggles.AnchorPoint = Vector2.new(0.5, 1)
	toggles.Position = UDim2.new(0.5, 0, 1, -20)
	toggles.Size = UDim2.new(0, 360, 0, 60)
	toggles.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	toggles.BackgroundTransparency = 0.25

	local togglesCorner = getOrCreate(toggles, "UICorner", "UICorner")
	togglesCorner.CornerRadius = UDim.new(0, 16)

	local listLayout = getOrCreate(toggles, "UIListLayout", "UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 12)

	local function createToggleButton(name, targetTab, text)
		local btn = getOrCreate(toggles, name, "TextButton")
		btn.Size = UDim2.new(0, 75, 0, 44)
		btn.BackgroundColor3 = Color3.fromRGB(35, 42, 60)
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn:SetAttribute("TargetTab", targetTab)
		
		local btnCorner = getOrCreate(btn, "UICorner", "UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		return btn
	end

	createToggleButton("ShopBtn", "Shop", "SHOP 🛒")
	createToggleButton("PassesBtn", "Passes", "PASSES 🎟️")
	createToggleButton("VIPBtn", "VIP", "VIP 👑")
	createToggleButton("SettingsBtn", "Settings", "SETTINGS ⚙️")

	-- 3. Tabs (ScreenGui, DisplayOrder = 10)
	local tabsGui = getOrCreate(parentRoot, "Tabs", "ScreenGui")
	tabsGui.DisplayOrder = 10
	tabsGui.ResetOnSpawn = false
	tabsGui.IgnoreGuiInset = true

	local blackOverlay = getOrCreate(tabsGui, "Black", "Frame")
	blackOverlay.Size = UDim2.new(1, 0, 1, 0)
	blackOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blackOverlay.BackgroundTransparency = 0.5
	blackOverlay.Visible = false

	-- Shop Modal Window
	local shopFrame = getOrCreate(tabsGui, "Shop", "Frame")
	shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	shopFrame.Size = UDim2.new(0, 560, 0, 380)
	shopFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	shopFrame.BackgroundTransparency = 0.15
	shopFrame.Visible = false

	local shopCorner = getOrCreate(shopFrame, "UICorner", "UICorner")
	shopCorner.CornerRadius = UDim.new(0, 16)

	local shopStroke = getOrCreate(shopFrame, "UIStroke", "UIStroke")
	shopStroke.Color = Color3.fromRGB(255, 215, 0)
	shopStroke.Thickness = 2

	local header = getOrCreate(shopFrame, "Header", "TextLabel")
	header.Position = UDim2.new(0, 20, 0, 15)
	header.Size = UDim2.new(0, 200, 0, 35)
	header.BackgroundTransparency = 1
	header.Text = "SHOP 🛒"
	header.TextColor3 = Color3.fromRGB(255, 215, 0)
	header.TextSize = 24
	header.Font = Enum.Font.GothamBlack
	header.TextXAlignment = Enum.TextXAlignment.Left

	local subTabsBar = getOrCreate(shopFrame, "TabButtons", "Frame")
	subTabsBar.Position = UDim2.new(0, 20, 0, 60)
	subTabsBar.Size = UDim2.new(1, -40, 0, 40)
	subTabsBar.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	subTabsBar.BackgroundTransparency = 0.3

	local subTabsCorner = getOrCreate(subTabsBar, "UICorner", "UICorner")
	subTabsCorner.CornerRadius = UDim.new(0, 10)

	local subTabsLayout = getOrCreate(subTabsBar, "UIListLayout", "UIListLayout")
	subTabsLayout.FillDirection = Enum.FillDirection.Horizontal
	subTabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	subTabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	subTabsLayout.Padding = UDim.new(0, 8)

	local function createSubTabBtn(name, targetTab, text)
		local btn = getOrCreate(subTabsBar, name, "TextButton")
		btn.Size = UDim2.new(0, 150, 0, 32)
		btn.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 13
		btn.Font = Enum.Font.GothamBold
		btn:SetAttribute("TargetTab", targetTab)
		
		local c = getOrCreate(btn, "UICorner", "UICorner")
		c.CornerRadius = UDim.new(0, 8)
		return btn
	end

	createSubTabBtn("GamePassesBtn", "GamePasses", "GAME PASSES 🎟️")
	createSubTabBtn("ProductsBtn", "Products", "BOOSTERS ⚡")
	createSubTabBtn("GachaBtn", "GachaSkins", "GACHA SKINS 🎲")

	local tabContents = getOrCreate(shopFrame, "TabContents", "Frame")
	tabContents.Position = UDim2.new(0, 20, 0, 110)
	tabContents.Size = UDim2.new(1, -40, 1, -125)
	tabContents.BackgroundTransparency = 1

	local passesFrame = getOrCreate(tabContents, "GamePasses", "ScrollingFrame")
	passesFrame.Size = UDim2.new(1, 0, 1, 0)
	passesFrame.BackgroundTransparency = 1
	passesFrame.ScrollBarThickness = 6

	local passesLayout = getOrCreate(passesFrame, "UIListLayout", "UIListLayout")
	passesLayout.FillDirection = Enum.FillDirection.Horizontal
	passesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	passesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	passesLayout.Padding = UDim.new(0, 15)

	local function createPassCard(name, titleText, descText, priceText)
		local card = getOrCreate(passesFrame, name, "Frame")
		card.Size = UDim2.new(0, 240, 0, 220)
		card.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
		
		local c = getOrCreate(card, "UICorner", "UICorner")
		c.CornerRadius = UDim.new(0, 12)
		
		local s = getOrCreate(card, "UIStroke", "UIStroke")
		s.Color = Color3.fromRGB(255, 215, 0)
		s.Thickness = 1.5
		
		local t = getOrCreate(card, "Title", "TextLabel")
		t.Position = UDim2.new(0, 10, 0, 12)
		t.Size = UDim2.new(1, -20, 0, 25)
		t.BackgroundTransparency = 1
		t.Text = titleText
		t.TextColor3 = Color3.fromRGB(255, 255, 255)
		t.TextSize = 16
		t.Font = Enum.Font.GothamBold
		
		local d = getOrCreate(card, "Desc", "TextLabel")
		d.Position = UDim2.new(0, 10, 0, 42)
		d.Size = UDim2.new(1, -20, 0, 50)
		d.BackgroundTransparency = 1
		d.Text = descText
		d.TextColor3 = Color3.fromRGB(180, 190, 210)
		d.TextSize = 12
		d.Font = Enum.Font.Gotham
		d.TextWrapped = true
		
		local buy = getOrCreate(card, "BuyBtn", "TextButton")
		buy.AnchorPoint = Vector2.new(0.5, 1)
		buy.Position = UDim2.new(0.5, 0, 1, -15)
		buy.Size = UDim2.new(1, -30, 0, 42)
		buy.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		buy.Text = "BUY FOR " .. priceText .. " R$"
		buy.TextColor3 = Color3.fromRGB(255, 255, 255)
		buy.TextSize = 14
		buy.Font = Enum.Font.GothamBold
		
		local bc = getOrCreate(buy, "UICorner", "UICorner")
		bc.CornerRadius = UDim.new(0, 8)
		return card
	end

	createPassCard("SuperGlueCard", "SUPER GLUE 🛡️", "Retain 50% of your stack when wiped out by a bump or trap!", "399")
	createPassCard("MegaDashCard", "MEGA DASH ⚡", "Increases your Dash Bump hitbox radius and launch distance by +100%!", "249")

	-- 4. OverlayGui (ScreenGui, DisplayOrder = 100)
	local overlayGui = getOrCreate(parentRoot, "OverlayGui", "ScreenGui")
	overlayGui.DisplayOrder = 100
	overlayGui.ResetOnSpawn = false
	overlayGui.IgnoreGuiInset = true

	local revengePrompt = getOrCreate(overlayGui, "RevengePrompt", "Frame")
	revengePrompt.AnchorPoint = Vector2.new(0.5, 0.5)
	revengePrompt.Position = UDim2.new(0.5, 0, 0.5, 0)
	revengePrompt.Size = UDim2.new(0, 380, 0, 220)
	revengePrompt.BackgroundColor3 = Color3.fromRGB(30, 15, 25)
	revengePrompt.BackgroundTransparency = 0.15
	revengePrompt.Visible = false

	local revengeCorner = getOrCreate(revengePrompt, "UICorner", "UICorner")
	revengeCorner.CornerRadius = UDim.new(0, 16)

	local revengeStroke = getOrCreate(revengePrompt, "UIStroke", "UIStroke")
	revengeStroke.Color = Color3.fromRGB(255, 50, 50)
	revengeStroke.Thickness = 3

	local revengeTitle = getOrCreate(revengePrompt, "Title", "TextLabel")
	revengeTitle.Position = UDim2.new(0, 15, 0, 15)
	revengeTitle.Size = UDim2.new(1, -30, 0, 30)
	revengeTitle.BackgroundTransparency = 1
	revengeTitle.Text = "YOU WERE WIPED OUT!"
	revengeTitle.TextColor3 = Color3.fromRGB(255, 75, 75)
	revengeTitle.TextSize = 22
	revengeTitle.Font = Enum.Font.GothamBlack

	local revengeBtn = getOrCreate(revengePrompt, "RevengeBtn", "TextButton")
	revengeBtn.AnchorPoint = Vector2.new(0.5, 1)
	revengeBtn.Position = UDim2.new(0.5, 0, 1, -20)
	revengeBtn.Size = UDim2.new(1, -40, 0, 50)
	revengeBtn.BackgroundColor3 = Color3.fromRGB(220, 35, 35)
	revengeBtn.Text = "NUCLEAR REVENGE FOR 29 R$ ⚡"
	revengeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	revengeBtn.TextSize = 16
	revengeBtn.Font = Enum.Font.GothamBlack

	local rBtnCorner = getOrCreate(revengeBtn, "UICorner", "UICorner")
	rBtnCorner.CornerRadius = UDim.new(0, 12)

	return true
end

return UIBuilder
