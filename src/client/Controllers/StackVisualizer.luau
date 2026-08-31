--!nonstrict
--[[
    StackVisualizer.luau
    Client controller handling local visual coin stack rendering and Lerp sway with ZERO impact on character physics or movement.
    Location: src/client/Controllers/StackVisualizer.luau (Syncs to StarterPlayerScripts.Client.Controllers.StackVisualizer)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local TemplateUtil = require(Shared:WaitForChild("Utils"):WaitForChild("TemplateUtil"))

local PlayerStackCounts: { [Player]: number } = {}
local PlayerVisualModels: { [Player]: { Part } } = {}

local VisualFolder: Folder
local StackVisualizer = {}

-- Create Client-Only Anchored Visual Coin Part by cloning CoinTemplate
local function createClientCoinPart(): Part
	local coin = TemplateUtil.CloneCoinTemplate() :: Part
	coin.Name = "VisualCoin"
	coin.Size = Vector3.new(0.3, 1.8, 1.8)
	coin.Anchored = true -- Anchored locally -> ZERO physical assembly inertia!
	coin.CanCollide = false
	coin.CanTouch = false
	coin.CanQuery = false
	coin.CastShadow = false
	return coin
end

-- Update Visual Model Parts for a Player
local function updatePlayerVisualParts(player: Player, targetCount: number)
	PlayerStackCounts[player] = targetCount

	if not PlayerVisualModels[player] then
		PlayerVisualModels[player] = {}
	end

	local partsList = PlayerVisualModels[player]
	local renderCount = math.min(targetCount, Config.MAX_RENDER_STACK)

	-- Add or remove parts to match render count
	while #partsList < renderCount do
		local part = createClientCoinPart()
		part.Parent = VisualFolder
		table.insert(partsList, part)
	end

	while #partsList > renderCount do
		local part = table.remove(partsList)
		if part then
			part:Destroy()
		end
	end
end

-- Clear Player Visual Parts
local function clearPlayerVisualParts(player: Player)
	if PlayerVisualModels[player] then
		for _, part in ipairs(PlayerVisualModels[player]) do
			if part then part:Destroy() end
		end
		PlayerVisualModels[player] = nil
	end
	PlayerStackCounts[player] = nil
end

function StackVisualizer.Init()
	VisualFolder = Workspace:FindFirstChild("ClientVisualStacks") :: Folder
	if not VisualFolder then
		VisualFolder = Instance.new("Folder")
		VisualFolder.Name = "ClientVisualStacks"
		VisualFolder.Parent = Workspace
	end

	-- Listen for Server Stack Updates
	local updateEvent = Remotes.Get("UpdateStack")
	if updateEvent then
		updateEvent.OnClientEvent:Connect(function(targetPlayer: Player, newCount: number)
			if targetPlayer and targetPlayer:IsA("Player") then
				updatePlayerVisualParts(targetPlayer, newCount)
			end
		end)
	end

	Players.PlayerRemoving:Connect(clearPlayerVisualParts)

	-- RenderStepped Visual Update Loop
	local playerSwayState = {}

	RunService.RenderStepped:Connect(function(dt: number)
		for player, partsList in pairs(PlayerVisualModels) do
			if not player or not player.Parent then
				clearPlayerVisualParts(player)
				continue
			end

			local character = player.Character
			if not character then continue end
			local head = character:FindFirstChild("Head") :: Part
			local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
			if not head or not hrp then continue end

			-- Calculate movement velocity sway
			local velocity = hrp.AssemblyLinearVelocity
			local localVel = hrp.CFrame:VectorToObjectSpace(velocity)

			if not playerSwayState[player] then
				playerSwayState[player] = { X = 0, Z = 0 }
			end
			local swayState = playerSwayState[player]

			local stackCount = PlayerStackCounts[player] or 0
			local stackFactor = math.max(1, stackCount) * 0.15
			local targetSwayX = math.clamp(-localVel.Z * 0.04 * stackFactor, -0.6, 0.6)
			local targetSwayZ = math.clamp(-localVel.X * 0.04 * stackFactor, -0.6, 0.6)

			swayState.X = swayState.X + (targetSwayX - swayState.X) * math.min(dt * 12, 1)
			swayState.Z = swayState.Z + (targetSwayZ - swayState.Z) * math.min(dt * 12, 1)

			-- Position visual parts locally above head (Head CFrame vs Upright Body Root CFrame)
			local baseRotation
			if Config.STACK_FOLLOW_HEAD_ROTATION then
				baseRotation = head.CFrame
			else
				local _, yaw, _ = hrp.CFrame:ToOrientation()
				baseRotation = CFrame.new(head.Position) * CFrame.Angles(0, yaw, 0)
			end

			for i, part in ipairs(partsList) do
				local progressiveTiltX = swayState.X * (1 + (i * 0.08))
				local progressiveTiltZ = swayState.Z * (1 + (i * 0.08))
				local offsetY = 1.5 + (i * 0.35)

				local partCFrame = baseRotation * CFrame.Angles(progressiveTiltX, 0, progressiveTiltZ) * CFrame.new(0, offsetY, 0) * CFrame.Angles(0, 0, math.rad(90))
				part.CFrame = partCFrame
			end
		end
	end)
end

return StackVisualizer
