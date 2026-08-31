--!nonstrict
--[[
    HitboxService.luau
    Dedicated server service managing full-body character HitboxCapsule creation, lifecycle destruction, and Strategy B event-driven target spatial queries.
    Location: src/server/Services/HitboxService.luau (Syncs to ServerScriptService.Server.Services.HitboxService)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule"))

local log = Logger.create("Combat")
local HitboxService = {}

-- ⚡ Strategy B Event-Driven Hitbox Cache Registry
local CachedHitboxes: { [Model]: BasePart } = {}

-- Create and weld a full-body HitboxCapsule to character/dummy HumanoidRootPart
function HitboxService.CreateHitbox(character: Model): BasePart?
	if not character then return nil end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return nil end

	local hitbox = character:FindFirstChild("HitboxCapsule") :: Part
	if not hitbox then
		-- Dynamically measure full-body bounding box extents of the character/dummy model
		local extents = character:GetExtentsSize()
		local hitboxWidth = math.max(4.0, extents.X + 0.5)
		local hitboxHeight = math.max(5.5, extents.Y + 0.5)
		local hitboxDepth = math.max(4.0, extents.Z + 0.5)

		hitbox = Instance.new("Part")
		hitbox.Name = "HitboxCapsule"
		hitbox.Size = Vector3.new(hitboxWidth, hitboxHeight, hitboxDepth)
		hitbox.Transparency = 1 -- Invisible in game
		hitbox.CanCollide = false
		hitbox.CanTouch = true
		hitbox.CanQuery = true
		hitbox.Massless = true
		hitbox.CFrame = hrp.CFrame
		hitbox.Parent = character

		local weld = Instance.new("WeldConstraint")
		weld.Name = "HitboxWeld"
		weld.Part0 = hrp
		weld.Part1 = hitbox
		weld.Parent = hitbox

		log(string.format("Created full-body HitboxCapsule for %s (Size: %.1f x %.1f x %.1f)", character.Name, hitboxWidth, hitboxHeight, hitboxDepth))
	end

	-- Register in Strategy B Cache
	CachedHitboxes[character] = hitbox

	-- Listen for model destruction to cleanly unregister
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			CachedHitboxes[character] = nil
		end
	end)

	return hitbox
end

-- Destroy character/dummy HitboxCapsule
function HitboxService.DestroyHitbox(character: Model)
	CachedHitboxes[character] = nil
	if character then
		local hitbox = character:FindFirstChild("HitboxCapsule")
		if hitbox then
			hitbox:Destroy()
		end
	end
end

-- Get Hitbox for a single player or model
function HitboxService.GetHitbox(model: Instance): BasePart?
	if model and model:IsA("Model") then
		return HitboxService.CreateHitbox(model)
	end
	return nil
end

-- Strategy B: Return cached array of HitboxCapsule parts with zero Workspace scanning
function HitboxService.GetTargetHitboxes(excludingPlayer: Player?): { BasePart }
	local hitboxes = {}
	local excludingChar = excludingPlayer and excludingPlayer.Character

	for model, hitbox in pairs(CachedHitboxes) do
		if model and model.Parent and hitbox and hitbox.Parent then
			if model ~= excludingChar then
				table.insert(hitboxes, hitbox)
			end
		else
			-- Clean stale entry
			CachedHitboxes[model] = nil
		end
	end

	return hitboxes
end

-- Initialize Service & Event Listeners
function HitboxService.Init()
	local function onCharacterAdded(character: Model)
		task.defer(function()
			HitboxService.CreateHitbox(character)
		end)
	end

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(character)
		end)
		if player.Character then
			onCharacterAdded(player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayerAdded(p)
	end

	-- Scan Workspace for existing NPC Dummies & dynamic additions
	Workspace.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.defer(function()
				if child:FindFirstChildOfClass("Humanoid") then
					HitboxService.CreateHitbox(child)
				end
			end)
		end
	end)

	log("HitboxService initialized successfully with Strategy B Event-Driven Cache.")
end

return HitboxService
