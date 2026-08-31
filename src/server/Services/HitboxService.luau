--!nonstrict
--[[
    HitboxService.luau
    Dedicated server service managing full-body character HitboxCapsule creation, extents measuring, lifecycle destruction, and target spatial queries for players & test dummies.
    Location: src/server/Services/HitboxService.luau (Syncs to ServerScriptService.Server.Services.HitboxService)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule"))

local log = Logger.create("Combat")
local HitboxService = {}

-- Create and weld a full-body HitboxCapsule to character/dummy HumanoidRootPart
function HitboxService.CreateHitbox(character: Model): BasePart?
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

	return hitbox
end

-- Destroy character/dummy HitboxCapsule
function HitboxService.DestroyHitbox(character: Model)
	local hitbox = character:FindFirstChild("HitboxCapsule")
	if hitbox then
		hitbox:Destroy()
	end
end

-- Get Hitbox for a single player or model
function HitboxService.GetHitbox(model: Instance): BasePart?
	if model and model:IsA("Model") then
		return HitboxService.CreateHitbox(model)
	end
	return nil
end

-- Get array of HitboxCapsule parts for all active opponent players & NPC test dummies
function HitboxService.GetTargetHitboxes(excludingPlayer: Player?): { BasePart }
	local hitboxes = {}
	local processedModels = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= excludingPlayer and player.Character then
			processedModels[player.Character] = true
			local hitbox = HitboxService.CreateHitbox(player.Character)
			if hitbox then
				table.insert(hitboxes, hitbox)
			end
		end
	end

	-- Also include any NPC Dummy models in Workspace with a Humanoid
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and not processedModels[child] then
			if child:FindFirstChildOfClass("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
				local excludingChar = excludingPlayer and excludingPlayer.Character
				if child ~= excludingChar then
					local hitbox = HitboxService.CreateHitbox(child)
					if hitbox then
						table.insert(hitboxes, hitbox)
					end
				end
			end
		end
	end

	return hitboxes
end

-- Initialize Service
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

	-- Scan Workspace for existing NPC Dummies
	Workspace.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
			task.defer(function()
				HitboxService.CreateHitbox(child)
			end)
		end
	end)

	log("HitboxService initialized successfully with Dummy NPC support.")
end

return HitboxService
