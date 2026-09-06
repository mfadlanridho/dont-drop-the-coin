--!strict
--[[
    CoinVisualizer.luau
    Client-side streaming-native controller for animating collectible CoinNode parts.
    Location: src/client/Controllers/CoinVisualizer.luau (Syncs to StarterPlayerScripts.Client.Controllers.CoinVisualizer)
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local CoinVisualizer = {}

local baseCFrames: { [BasePart]: CFrame } = {}
local renderConn: RBXScriptConnection? = nil

local animCfg = (Config.COIN_SPAWNER and Config.COIN_SPAWNER.ANIMATION) or {}
local ROTATION_SPEED = animCfg.ROTATION_SPEED or 2.5
local BOB_AMPLITUDE = animCfg.BOB_AMPLITUDE or 0.35
local BOB_FREQUENCY = animCfg.BOB_FREQUENCY or 3.0
local NODE_TAG = (Config.COIN_SPAWNER and Config.COIN_SPAWNER.NODE_TAG) or "CoinNode"

local function updateRenderLoopState()
	local hasCoins = next(baseCFrames) ~= nil
	if hasCoins and not renderConn then
		renderConn = RunService.RenderStepped:Connect(function()
			local now = os.clock()
			local spinCFrame = CFrame.Angles(0, (now * ROTATION_SPEED) % (math.pi * 2), 0)
			local bobVector = Vector3.new(0, math.sin(now * BOB_FREQUENCY) * BOB_AMPLITUDE, 0)

			for part, baseCF in pairs(baseCFrames) do
				if part.Transparency < 1 and part.Parent then
					part.CFrame = CFrame.new(baseCF.Position + bobVector) * spinCFrame * baseCF.Rotation
				end
			end
		end)
	elseif not hasCoins and renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
end

local function bindCoin(inst: Instance)
	if inst:IsA("BasePart") and not baseCFrames[inst] then
		baseCFrames[inst] = inst.CFrame
		updateRenderLoopState()
	end
end

local function unbindCoin(inst: Instance)
	if inst:IsA("BasePart") and baseCFrames[inst] then
		baseCFrames[inst] = nil
		updateRenderLoopState()
	end
end

function CoinVisualizer.Init()
	for _, inst in ipairs(CollectionService:GetTagged(NODE_TAG)) do
		bindCoin(inst)
	end

	CollectionService:GetInstanceAddedSignal(NODE_TAG):Connect(bindCoin)
	CollectionService:GetInstanceRemovedSignal(NODE_TAG):Connect(unbindCoin)

	print("[CoinVisualizer] Initialized minimal streaming-native visualizer.")
end

return CoinVisualizer
