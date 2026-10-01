--!strict
--[[
    RebirthController.luau
    Client controller managing Rebirth HUD Progress Bar and Confirmation Modal.
    Binds directly to existing Roblox Studio UI instances in PlayerGui.MainHUD and PlayerGui.OverlayGui.
    100% reactive to leaderstats.Coins and leaderstats.Rebirths with zero network sync overhead.
    Zero runtime UI instantiation in code.
    Location: src/client/Controllers/RebirthController.luau (Syncs to StarterPlayerScripts.Client.Controllers.RebirthController)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Packages = ReplicatedStorage:WaitForChild("Packages")
local RebirthModule = require(Packages:WaitForChild("RebirthModule") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RebirthConfig = require(Shared:WaitForChild("Config"):WaitForChild("RebirthConfig") :: ModuleScript)
local Remotes = require(Shared:WaitForChild("Remotes"))
local NotificationService = require(Shared:WaitForChild("UI"):WaitForChild("NotificationService"))

local RebirthController = {}

local TWEEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local latestData = {
	CurrentRebirth = 0,
	Multiplier = 1.0,
	Evaluation = nil :: any,
}

-- References to Studio UI instances
local progressContainer: Frame? = nil
local fillBar: Frame? = nil
local progressLabel: TextLabel? = nil
local titleLabel: TextLabel? = nil
local borderStroke: UIStroke? = nil

local modalContainer: Frame? = nil
local modalOverlay: TextButton? = nil
local modalTitle: TextLabel? = nil
local boostBanner: TextLabel? = nil
local confirmBtn: TextButton? = nil
local cancelBtn: TextButton? = nil

--- Updates the visual progress bar elements in the HUD
local function updateProgressBarUI()
	if not progressContainer or not fillBar or not progressLabel or not titleLabel then return end

	local currentRebirth = latestData.CurrentRebirth
	local eval = latestData.Evaluation
	local mult = latestData.Multiplier

	local ratio = (eval and eval.OverallProgress) or 0
	local isReady = eval and eval.AllMet or false
	local progressText = (eval and eval.Primary and eval.Primary.Description) or "0 / 1,000 Coins"
	local titleText = string.format("⭐ REBIRTH %d  (%.2fx CASH BOOST)", currentRebirth, mult)

	titleLabel.Text = titleText

	local targetSize = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
	TweenService:Create(fillBar, TWEEN_INFO, { Size = targetSize }):Play()

	if isReady then
		progressLabel.Text = "✨ " .. progressText .. " (CLICK TO REBIRTH!)"
		titleLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
		if borderStroke then
			borderStroke.Color = Color3.fromRGB(255, 215, 0)
			borderStroke.Thickness = 2.5
		end
	else
		progressLabel.Text = progressText
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
		if borderStroke then
			borderStroke.Color = Color3.fromRGB(60, 70, 95)
			borderStroke.Thickness = 1.5
		end
	end
end

--- Recalculates progress locally from player leaderstats currency
local function recalculateLocalProgress()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local coins = 0
	local rebirths = 0

	if leaderstats then
		local coinsVal = leaderstats:FindFirstChild("Coins") :: IntValue?
		if coinsVal then
			coins = coinsVal.Value
		end
		local rebirthsVal = leaderstats:FindFirstChild("Rebirths") :: IntValue?
		if rebirthsVal then
			rebirths = rebirthsVal.Value
		end
	end

	latestData.CurrentRebirth = rebirths
	latestData.Multiplier = RebirthModule.GetMultiplier(RebirthConfig, rebirths)
	latestData.Evaluation = RebirthModule.Evaluate(RebirthConfig, rebirths, {
		Coins = coins,
	})

	updateProgressBarUI()
end

--- Opens the Studio Confirmation Modal
function RebirthController.OpenModal()
	if not modalContainer then return end

	recalculateLocalProgress()

	local currentRebirth = latestData.CurrentRebirth
	local curMult = latestData.Multiplier
	local nextMult = curMult + 0.25

	if boostBanner then
		boostBanner.Text = string.format("Income Boost: %.2fx ➔ %.2fx (+25%%)", curMult, nextMult)
	end

	local eval = latestData.Evaluation
	local isEligible = eval and eval.AllMet

	if confirmBtn then
		if isEligible then
			confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
			confirmBtn.Text = "REBIRTH NOW"
		else
			confirmBtn.BackgroundColor3 = Color3.fromRGB(100, 105, 115)
			confirmBtn.Text = "LOCKED (Need Coins)"
		end
	end

	modalContainer.Visible = true
end

--- Closes the Confirmation Modal
function RebirthController.CloseModal()
	if modalContainer then
		modalContainer.Visible = false
	end
end

--- Binds to Studio MainHUD and OverlayGui instances in PlayerGui
local function bindGuiInstances()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	-- 1. Bind to StarterGui.MainHUD.RebirthProgress
	task.spawn(function()
		local mainHud = playerGui:WaitForChild("MainHUD", 15) :: ScreenGui?
		if not mainHud then return end

		local progress = mainHud:WaitForChild("RebirthProgress", 10) :: Frame?
		if not progress then return end

		progressContainer = progress
		borderStroke = progress:FindFirstChild("BorderStroke") :: UIStroke?
		titleLabel = progress:FindFirstChild("TitleLabel") :: TextLabel?

		local barTrack = progress:FindFirstChild("BarTrack") :: Frame?
		if barTrack then
			fillBar = barTrack:FindFirstChild("FillBar") :: Frame?
			progressLabel = barTrack:FindFirstChild("ProgressLabel") :: TextLabel?
		end

		local actionBtn = progress:FindFirstChild("ActionButton") :: TextButton?
		if actionBtn then
			actionBtn.MouseButton1Click:Connect(function()
				RebirthController.OpenModal()
			end)
		end

		recalculateLocalProgress()
	end)

	-- 2. Bind to StarterGui.OverlayGui.RebirthModal
	task.spawn(function()
		local overlayGui = playerGui:WaitForChild("OverlayGui", 15) :: ScreenGui?
		if not overlayGui then return end

		local modal = overlayGui:WaitForChild("RebirthModal", 10) :: Frame?
		if not modal then return end

		modalContainer = modal
		modalOverlay = modal:FindFirstChild("Overlay") :: TextButton?

		local card = modal:FindFirstChild("Card") :: Frame?
		if card then
			modalTitle = card:FindFirstChild("Title") :: TextLabel?
			boostBanner = card:FindFirstChild("BoostBanner") :: TextLabel?

			local btnContainer = card:FindFirstChild("BtnContainer") :: Frame?
			if btnContainer then
				cancelBtn = btnContainer:FindFirstChild("CancelBtn") :: TextButton?
				confirmBtn = btnContainer:FindFirstChild("ConfirmBtn") :: TextButton?
			end
		end

		if modalOverlay then
			modalOverlay.MouseButton1Click:Connect(RebirthController.CloseModal)
		end
		if cancelBtn then
			cancelBtn.MouseButton1Click:Connect(RebirthController.CloseModal)
		end

		if confirmBtn then
			confirmBtn.MouseButton1Click:Connect(function()
				recalculateLocalProgress()
				local eval = latestData.Evaluation
				if not eval or not eval.AllMet then
					NotificationService.Send({
						Title = "REQUIREMENTS NOT MET",
						Description = "You don't have enough coins yet to Rebirth!",
						Duration = 3,
						Color = Color3.fromRGB(255, 80, 80),
					})
					return
				end

				RebirthController.CloseModal()
				local requestRemote = Remotes.Get("RequestRebirth")
				if requestRemote then
					requestRemote:FireServer()
				end
			end)
		end
	end)
end

function RebirthController.Init()
	bindGuiInstances()

	-- Re-bind if PlayerGui resets or ScreenGuis recreate
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "MainHUD" or child.Name == "OverlayGui" then
			task.defer(bindGuiInstances)
		end
	end)

	-- React to leaderstats currency changes (instant local calculation)
	task.spawn(function()
		local leaderstats = LocalPlayer:WaitForChild("leaderstats", 15) :: Folder?
		if leaderstats then
			local coinsVal = leaderstats:WaitForChild("Coins", 10) :: IntValue?
			local rebirthsVal = leaderstats:WaitForChild("Rebirths", 10) :: IntValue?

			if coinsVal then
				coinsVal.Changed:Connect(recalculateLocalProgress)
			end
			if rebirthsVal then
				rebirthsVal.Changed:Connect(recalculateLocalProgress)
			end

			recalculateLocalProgress()
		end
	end)

	local successRemote = Remotes.Get("RebirthSuccess")
	if successRemote then
		successRemote.OnClientEvent:Connect(function(payload: any)
			local newRebirth = payload and payload.NewRebirth or 1
			local multiplier = payload and payload.Multiplier or 1.25

			NotificationService.Send({
				Title = "🌟 PRESTIGE ASCENSION!",
				Description = string.format("Congratulations! You are now Rebirth Level %d with a %.2fx Cash Multiplier!", newRebirth, multiplier),
				Duration = 5,
				Color = Color3.fromRGB(255, 215, 0),
			})

			-- Celebration Sound
			local AudioModule = Packages:FindFirstChild("AudioModule")
			if AudioModule then
				local Audio = require(AudioModule :: ModuleScript) :: any
				if Audio and typeof(Audio.playOneShot) == "function" then
					Audio.playOneShot("BankCoins", nil, { volume = 1.0, pitch = 1.2 })
				end
			end
		end)
	end
end

return RebirthController
