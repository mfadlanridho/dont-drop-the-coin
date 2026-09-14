--!nonstrict
--[[
    GuardAIService.luau
    Server orchestrator that binds and spawns Guard and Drone NPC AI models across ZoneFloors and hazard platforms.
    Subscribes to ZoneService.OnZoneFloorDiscovered for decoupled floor arena integration.
    Location: src/server/Services/GuardAIService.luau (Syncs to ServerScriptService.Server.Services.GuardAIService)
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule"))
local GuardAI = require(Packages:WaitForChild("GuardAIModule"))

local log = Logger.create("Combat")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Services = script.Parent
local CombatServer = require(Services:WaitForChild("CombatServer"))
local HitboxService = require(Services:WaitForChild("HitboxService"))
local ZoneService = require(Services:WaitForChild("ZoneService"))

local GuardAIService = {}
local activeGuards: { [Model]: any } = {}
local spawnedGuardModels: { [Model]: boolean } = {}

-- Unbind an NPC Model from GuardAI
local function unbindGuardModel(model: Model)
	local guard = activeGuards[model]
	if guard then
		if typeof(guard.destroy) == "function" then
			guard:destroy()
		end
		activeGuards[model] = nil
		log(string.format("[GuardAIService] Unbound GuardAI from model %s", model.Name))
	end
end

--- Attaches animation tracks to the guard's Humanoid.Animator driven by Humanoid.Running
local function attachGuardAnimations(model: Model, anims: { [string]: string }?): AnimationTrack?
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return nil end

	local animator = humanoid:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- If anims not explicitly passed, resolve from Config.GUARD_TEMPLATES by model name
	if not anims and Config.GUARD_TEMPLATES then
		local baseName = model.Name:gsub("_%d+$", "")
		local tDef = Config.GUARD_TEMPLATES[model.Name] or Config.GUARD_TEMPLATES[baseName]
		if tDef then
			anims = tDef.Animations
		end
	end

	local idleTrack: AnimationTrack? = nil
	local walkTrack: AnimationTrack? = nil
	local attackTrack: AnimationTrack? = nil

	local idleId = anims and anims.Idle
	local walkId = anims and anims.Walk
	local attackId = anims and anims.Attack

	-- Fallback to model-embedded Anims folder if present
	local animsFolder = model:FindFirstChild("Anims")
	if animsFolder then
		if not idleId or not idleId:match("^rbxassetid://%d+") then
			local a = animsFolder:FindFirstChild("Idle")
			if a and a:IsA("Animation") and a.AnimationId ~= "" then idleId = a.AnimationId end
		end
		if not walkId or not walkId:match("^rbxassetid://%d+") then
			local a = animsFolder:FindFirstChild("Walk")
			if a and a:IsA("Animation") and a.AnimationId ~= "" then walkId = a.AnimationId end
		end
		if not attackId or not attackId:match("^rbxassetid://%d+") then
			local a = animsFolder:FindFirstChild("Attack")
			if a and a:IsA("Animation") and a.AnimationId ~= "" then attackId = a.AnimationId end
		end
	end

	if idleId and idleId:match("^rbxassetid://%d+") then
		local anim = Instance.new("Animation")
		anim.AnimationId = idleId
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Idle
			track.Looped = true
			idleTrack = track
			track:Play(0.2)
		end
	end

	if walkId and walkId:match("^rbxassetid://%d+") then
		local anim = Instance.new("Animation")
		anim.AnimationId = walkId
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Movement
			track.Looped = true
			walkTrack = track
		end
	end

	if attackId and attackId:match("^rbxassetid://%d+") then
		local anim = Instance.new("Animation")
		anim.AnimationId = attackId
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = false
			attackTrack = track
		end
	end

	-- Connect Humanoid.Running to toggle Idle vs Walk tracks smoothly
	if idleTrack or walkTrack then
		humanoid.Running:Connect(function(speed)
			if speed > 0.5 then
				if walkTrack and not walkTrack.IsPlaying then walkTrack:Play(0.2) end
				if idleTrack and idleTrack.IsPlaying then idleTrack:Stop(0.2) end
			else
				if idleTrack and not idleTrack.IsPlaying then idleTrack:Play(0.2) end
				if walkTrack and walkTrack.IsPlaying then walkTrack:Stop(0.2) end
			end
		end)
	end

	return attackTrack
end

-- Bind an NPC Model to GuardAI with optional floor overrides
local function bindGuardModel(model: Model, customConfig: { [string]: any }?)
	if activeGuards[model] then return end
	if not model:IsA("Model") then return end

	local locomotionMode = (customConfig and customConfig.locomotionMode) or model:GetAttribute("LocomotionMode") or "Walk"
	local moveSpeed = (customConfig and customConfig.moveSpeed) or model:GetAttribute("MoveSpeed") or 14
	local detectionRadius = (customConfig and customConfig.detectionRadius) or model:GetAttribute("DetectionRadius") or 35
	local attackRadius = (customConfig and customConfig.attackRadius) or model:GetAttribute("AttackRadius") or 5.0
	local platformPart = (customConfig and customConfig.platformPart)

	-- Load Animations if provided
	local animConfig = (customConfig and customConfig.animations)
	local attackTrack = attachGuardAnimations(model, animConfig)

	activeGuards[model] = GuardAI.new(model, {
		locomotionMode = locomotionMode,
		moveSpeed = moveSpeed,
		detectionRadius = detectionRadius,
		attackRadius = attackRadius,
		platformPart = platformPart,
		onAttackHit = function(victimModel: Model)
			if attackTrack and not attackTrack.IsPlaying then
				attackTrack:Play(0.1)
			end
			log(string.format("[GuardAIService] %s struck %s!", model.Name, victimModel.Name))
			CombatServer.BumpVictimModel(nil, victimModel)
		end,
	})

	model.Destroying:Connect(function()
		unbindGuardModel(model)
		spawnedGuardModels[model] = nil
	end)

	log(string.format("[GuardAIService] Bound GuardAI to model %s (Speed: %d, Mode: %s)", model.Name, moveSpeed, locomotionMode))
end

--- Resolves a template model from ReplicatedStorage.Templates.Guards (checks tier template, then default template, then creates fallback)
local function resolveOrCreateGuardTemplate(templateName: string, tier: number, defaultTemplateName: string?): Model
	local templatesFolder = ReplicatedStorage:FindFirstChild("Templates")
	local guardsFolder = templatesFolder and templatesFolder:FindFirstChild("Guards")

	-- 1. Try to find the specific tier template
	local customTemplate = (guardsFolder and guardsFolder:FindFirstChild(templateName))
		or (templatesFolder and templatesFolder:FindFirstChild(templateName))

	-- 2. Two-tier fallback: If tier template not found, check the DEFAULT template
	if not customTemplate and defaultTemplateName and defaultTemplateName ~= "" and defaultTemplateName ~= templateName then
		customTemplate = (guardsFolder and guardsFolder:FindFirstChild(defaultTemplateName))
			or (templatesFolder and templatesFolder:FindFirstChild(defaultTemplateName))
	end

	if customTemplate and customTemplate:IsA("Model") then
		return customTemplate:Clone()
	end

	-- 3. Final Fallback: Create a clean stylized R15 dummy matching the zone tier color
	local tierData = Config.ZONE_TIERS and Config.ZONE_TIERS[tier]
	local tierColor = tierData and tierData.Color or Color3.fromRGB(255, 120, 0)

	local dummy = Instance.new("Model")
	dummy.Name = templateName

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = false
	hrp.Parent = dummy

	local torso = Instance.new("Part")
	torso.Name = "UpperTorso"
	torso.Size = Vector3.new(2.4, 2.6, 1.4)
	torso.Color = tierColor
	torso.Material = Enum.Material.Neon
	torso.CanCollide = true
	torso.Anchored = false
	torso.Position = hrp.Position + Vector3.new(0, 1.3, 0)
	torso.Parent = dummy

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Color = Color3.fromRGB(240, 240, 240)
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.Anchored = false
	head.Position = torso.Position + Vector3.new(0, 1.8, 0)
	head.Parent = dummy

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.MaxHealth = 200
	humanoid.Health = 200
	humanoid.Parent = dummy

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = hrp
	w1.Part1 = torso
	w1.Parent = torso

	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = torso
	w2.Part1 = head
	w2.Parent = head

	dummy.PrimaryPart = hrp
	return dummy
end

--- Ensures a perimeter patrol circuit exists for a floor slab (handles cylinder arenas safely)
local function ensureWaypoints(zoneFloor: Instance, slab: BasePart): Folder
	local existing = zoneFloor:FindFirstChild("Waypoints")
	if existing and existing:IsA("Folder") and #existing:GetChildren() > 0 then
		-- Validate that existing waypoints don't poke outside circular/cylinder slabs
		local isCyl = slab:IsA("Part") and slab.Shape == Enum.PartType.Cylinder
		local maxRadius = if isCyl then (math.min(slab.Size.Y, slab.Size.Z) / 2) else (math.min(slab.Size.X, slab.Size.Z) / 2)
		local allValid = true
		for _, wp in ipairs(existing:GetChildren()) do
			if wp:IsA("BasePart") then
				local d = Vector2.new(wp.Position.X - slab.Position.X, wp.Position.Z - slab.Position.Z).Magnitude
				if d > (maxRadius - 5) then
					allValid = false
					break
				end
			end
		end
		if allValid then
			return existing
		end
		existing:ClearAllChildren()
	end

	local folder = existing or Instance.new("Folder")
	folder.Name = "Waypoints"
	folder.Parent = zoneFloor

	local center = slab.Position
	local isCylinder = slab:IsA("Part") and slab.Shape == Enum.PartType.Cylinder
	local radius = if isCylinder then (math.min(slab.Size.Y, slab.Size.Z) / 2) else (math.min(slab.Size.X, slab.Size.Z) / 2)
	local patrolRadius = math.max(10, radius - 16)
	local topY = slab.Position.Y + (slab.Size.X / 2) + 2

	-- 4 cardinal perimeter waypoints (North, East, South, West)
	local offsets = {
		Vector3.new(patrolRadius, 0, 0),
		Vector3.new(0, 0, patrolRadius),
		Vector3.new(-patrolRadius, 0, 0),
		Vector3.new(0, 0, -patrolRadius),
	}

	for i, off in ipairs(offsets) do
		local wp = Instance.new("Part")
		wp.Name = string.format("Waypoint_%d", i)
		wp.Size = Vector3.new(1, 1, 1)
		wp.Position = Vector3.new(center.X + off.X, topY, center.Z + off.Z)
		wp.Anchored = true
		wp.CanCollide = false
		wp.Transparency = 1
		wp.Parent = folder
	end

	return folder
end

--- Event listener: spawns/binds floor guards when ZoneService discovers a ZoneFloor
local function onZoneFloorDiscovered(zoneData: any)
	local zoneModel = zoneData.ZoneModel
	local zoneTier = zoneData.ZoneTier
	local slab = zoneData.FloorSlab
	local floorFolder = zoneModel:FindFirstChild("ZoneFloor")
	if not floorFolder then return end

	-- Fetch guard configuration from Config.ZONE_GUARDS
	local defaultCfg = (Config.ZONE_GUARDS and Config.ZONE_GUARDS.DEFAULT) or {}
	local tierCfg = (Config.ZONE_GUARDS and Config.ZONE_GUARDS[zoneTier]) or {}

	local templateName = tierCfg.TemplateName or defaultCfg.TemplateName or string.format("Guard_Tier%d", zoneTier)
	local count = tierCfg.Count or defaultCfg.Count or 1

	-- Resolve template definition from Config.GUARD_TEMPLATES
	local templateDef = (Config.GUARD_TEMPLATES and Config.GUARD_TEMPLATES[templateName])
		or (defaultCfg.TemplateName and Config.GUARD_TEMPLATES and Config.GUARD_TEMPLATES[defaultCfg.TemplateName])

	local anims = (templateDef and templateDef.Animations) or tierCfg.Animations or defaultCfg.Animations
	local moveSpeed = tierCfg.MoveSpeed or (templateDef and templateDef.MoveSpeed) or (templateDef and templateDef.BaseSpeed) or defaultCfg.MoveSpeed or 14
	local detectionRadius = tierCfg.DetectionRadius or defaultCfg.DetectionRadius or 35
	local attackRadius = tierCfg.AttackRadius or (templateDef and templateDef.AttackRadius) or defaultCfg.AttackRadius or 5.0

	-- Ensure waypoints exist for this floor
	ensureWaypoints(floorFolder, slab)

	-- Check if guard models already exist in zoneFloor (Studio-placed priority)
	local existingGuards: { Model } = {}
	for _, child in ipairs(floorFolder:GetChildren()) do
		if child:IsA("Model") and (child.Name:match("Guard") or CollectionService:HasTag(child, "GuardNPC")) then
			table.insert(existingGuards, child)
		end
	end

	-- If builder-placed guards exist, bind them with the slab platform boundary!
	if #existingGuards > 0 then
		for _, guard in ipairs(existingGuards) do
			bindGuardModel(guard, {
				platformPart = slab,
				moveSpeed = moveSpeed,
				detectionRadius = detectionRadius,
				attackRadius = attackRadius,
				animations = anims,
			})
		end
		return
	end

	-- Otherwise, auto-spawn the configured count of guards
	for i = 1, count do
		local guardModel = resolveOrCreateGuardTemplate(templateName, zoneTier, defaultCfg.TemplateName)
		local guardName = if count > 1 then string.format("%s_%d", templateName, i) else templateName
		guardModel.Name = guardName

		-- Auto-resolve PrimaryPart if not explicitly set on the custom rig
		if not guardModel.PrimaryPart then
			guardModel.PrimaryPart = guardModel:FindFirstChild("HumanoidRootPart")
				or guardModel:FindFirstChildWhichIsA("MeshPart")
				or guardModel:FindFirstChildWhichIsA("BasePart")
		end

		-- Position floating above the slab surface
		local offsetSpread = if count > 1 then Vector3.new((i - 1.5) * 16, 3, 0) else Vector3.new(0, 3, 0)
		local spawnPos = zoneData.SurfaceCenter + offsetSpread
		if guardModel.PrimaryPart then
			guardModel:SetPrimaryPartCFrame(CFrame.new(spawnPos))
		end

		guardModel.Parent = floorFolder
		CollectionService:AddTag(guardModel, "GuardNPC")
		spawnedGuardModels[guardModel] = true

		-- Attach Hitbox
		HitboxService.CreateHitbox(guardModel)

		-- Bind to GuardAI
		bindGuardModel(guardModel, {
			platformPart = slab,
			moveSpeed = moveSpeed,
			detectionRadius = detectionRadius,
			attackRadius = attackRadius,
			animations = anims,
		})

		log(string.format("[GuardAIService] Spawned %s on %s floor (Speed: %d, AttackRadius: %.1f)",
			guardName, zoneModel.Name, moveSpeed, attackRadius))
	end
end

--- Resets cached state and removes spawned guards (useful for live reload / tests)
function GuardAIService.Cleanup()
	for model, _ in pairs(activeGuards) do
		unbindGuardModel(model)
	end
	for model, _ in pairs(spawnedGuardModels) do
		if model and model.Parent then
			model:Destroy()
		end
	end
	table.clear(activeGuards)
	table.clear(spawnedGuardModels)
end

-- Initialize Service & Listen to Tags/Folders
function GuardAIService.Init()
	-- 1. Connect to ZoneService for event-driven floor guard spawning & boundary leashing
	ZoneService.OnZoneFloorDiscovered(onZoneFloorDiscovered)

	-- 2. Tag: GuardNPC (for any custom placed guards outside zone floors)
	for _, instance in ipairs(CollectionService:GetTagged("GuardNPC")) do
		if instance:IsA("Model") then
			bindGuardModel(instance)
		end
	end
	CollectionService:GetInstanceAddedSignal("GuardNPC"):Connect(function(instance)
		if instance:IsA("Model") then
			bindGuardModel(instance)
		end
	end)
	CollectionService:GetInstanceRemovedSignal("GuardNPC"):Connect(function(instance)
		if instance:IsA("Model") then
			unbindGuardModel(instance)
		end
	end)

	-- 3. Scan Workspace.Hazards for standalone platform models containing guard models
	local hazardsFolder = Workspace:FindFirstChild("Hazards")
	if hazardsFolder then
		for _, descendant in ipairs(hazardsFolder:GetDescendants()) do
			if descendant:IsA("Model") and (descendant.Name:match("Drone") or descendant.Name:match("Guard")) then
				bindGuardModel(descendant)
			end
		end

		hazardsFolder.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("Model") and (descendant.Name:match("Drone") or descendant.Name:match("Guard")) then
				bindGuardModel(descendant)
			end
		end)
	end

	log("[GuardAIService] Initialized Universal Guard AI Service with ZoneService integration.")
end

return GuardAIService
