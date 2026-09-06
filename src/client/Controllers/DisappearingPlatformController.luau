--!nonstrict
--[[
    DisappearingPlatformController.luau
    Client-side deterministic controller for Zone 3 Disappearing Platforms.
    Listens to the replicated "PlatformState" attribute ("Stable", "Warning", "Vanished")
    and executes local smooth tweens, 0ms latency collision toggles (CanCollide = false),
    and forces HumanoidStateType.Freefall to completely eliminate floating/stuck humanoid physics bugs.
    Location: src/client/Controllers/DisappearingPlatformController.luau
--]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

local log = Logger.create("Hazards")
local localPlayer = Players.LocalPlayer

local DisappearingPlatformController = {}

type PartRecord = {
	part: BasePart,
	originalColor: Color3,
	originalTransparency: number,
	activeTween: Tween?,
}

type PlatformBinding = {
	instance: Instance,
	records: { PartRecord },
	conn: RBXScriptConnection?,
	ancestryConn: RBXScriptConnection?,
}

local boundPlatforms: { [Instance]: PlatformBinding } = {}

-- Checks if local player is currently on or directly above any of the platform parts
local function isLocalPlayerOnPlatform(records: { PartRecord }): boolean
	local character = localPlayer.Character
	if not character then return false end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false end

	local playerPos = hrp.Position
	for _, rec in ipairs(records) do
		local part = rec.part
		if part and part.Parent then
			local rel = part.CFrame:PointToObjectSpace(playerPos)
			local halfSize = part.Size * 0.5
			-- Check horizontal footprint (with 1 stud margin) and vertical height above floor
			if math.abs(rel.X) <= (halfSize.X + 1.0)
				and math.abs(rel.Z) <= (halfSize.Z + 1.0)
				and rel.Y >= -1.0
				and rel.Y <= (halfSize.Y + 7.0)
			then
				return true
			end
		end
	end
	return false
end

-- Apply state visual & collision changes locally
local function applyState(binding: PlatformBinding, state: string)
	local inst = binding.instance
	local warningDelay = inst:GetAttribute("WarningDelay") or 0.85
	local warningColor = inst:GetAttribute("WarningColor") or Color3.fromRGB(255, 60, 60)

	if state == "Warning" then
		-- 1. Warning Phase: Smooth 60+ FPS client-side color tween
		for _, rec in ipairs(binding.records) do
			if rec.part and rec.part.Parent then
				if rec.activeTween then
					rec.activeTween:Cancel()
					rec.activeTween = nil
				end

				local tween = TweenService:Create(
					rec.part,
					TweenInfo.new(warningDelay, Enum.EasingStyle.Linear),
					{ Color = warningColor, Transparency = math.max(0.35, rec.originalTransparency) }
				)
				rec.activeTween = tween
				tween:Play()
			end
		end

	elseif state == "Vanished" then
		-- 2. Vanished Phase: Cancel active tweens, drop local collision & turn invisible
		for _, rec in ipairs(binding.records) do
			if rec.activeTween then
				rec.activeTween:Cancel()
				rec.activeTween = nil
			end
			if rec.part and rec.part.Parent then
				rec.part.CanCollide = false
				rec.part.Transparency = 1
			end
		end

		-- Hide any attached GUI labels
		for _, gui in ipairs(inst:GetDescendants()) do
			if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
				gui.Enabled = false
			end
		end

		-- If local player was standing on this platform, force immediate Freefall (kills floating bug)
		if isLocalPlayerOnPlatform(binding.records) then
			local char = localPlayer.Character
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end

	elseif state == "Stable" then
		-- 3. Stable Phase: Cancel any tween and restore solid state
		for _, rec in ipairs(binding.records) do
			if rec.activeTween then
				rec.activeTween:Cancel()
				rec.activeTween = nil
			end
			if rec.part and rec.part.Parent then
				rec.part.Color = rec.originalColor
				rec.part.Transparency = rec.originalTransparency
				rec.part.CanCollide = true
			end
		end

		-- Restore any attached GUI labels
		for _, gui in ipairs(inst:GetDescendants()) do
			if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
				gui.Enabled = true
			end
		end
	end
end

-- Bind a platform instance on the client
local function bindClientPlatform(instance: Instance)
	if boundPlatforms[instance] then return end

	local records: { PartRecord } = {}
	if instance:IsA("BasePart") then
		table.insert(records, {
			part = instance,
			originalColor = instance.Color,
			originalTransparency = instance.Transparency,
			activeTween = nil,
		})
	elseif instance:IsA("Model") then
		for _, desc in ipairs(instance:GetDescendants()) do
			if desc:IsA("BasePart") then
				table.insert(records, {
					part = desc,
					originalColor = desc.Color,
					originalTransparency = desc.Transparency,
					activeTween = nil,
				})
			end
		end
	end

	if #records == 0 then return end

	local binding: PlatformBinding = {
		instance = instance,
		records = records,
		conn = nil,
		ancestryConn = nil,
	}

	-- Listen for replicated state changes
	binding.conn = instance:GetAttributeChangedSignal("PlatformState"):Connect(function()
		local currentState = instance:GetAttribute("PlatformState") or "Stable"
		applyState(binding, currentState :: string)
	end)

	-- Auto-cleanup on removal
	binding.ancestryConn = instance.AncestryChanged:Connect(function(_, parent)
		if not parent then
			if binding.conn then
				binding.conn:Disconnect()
				binding.conn = nil
			end
			if binding.ancestryConn then
				binding.ancestryConn:Disconnect()
				binding.ancestryConn = nil
			end
			for _, rec in ipairs(binding.records) do
				if rec.activeTween then
					rec.activeTween:Cancel()
					rec.activeTween = nil
				end
			end
			boundPlatforms[instance] = nil
		end
	end)

	boundPlatforms[instance] = binding

	-- Apply initial state (handles late-joiners)
	local initialState = instance:GetAttribute("PlatformState") or "Stable"
	applyState(binding, initialState :: string)
end

local TAG_NAME = "Hazard_DisappearingPlatform"

function DisappearingPlatformController.Init()
	-- 100% Streaming-Native: Driven purely through CollectionService
	for _, inst in ipairs(CollectionService:GetTagged(TAG_NAME)) do
		task.spawn(bindClientPlatform, inst)
	end
	CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(bindClientPlatform)

	log("[DisappearingPlatformController] Initialized streaming-native CollectionService controller.")
end

return DisappearingPlatformController
