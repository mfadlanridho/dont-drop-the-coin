--!strict
--[[
    SpeedSurgeEffect.luau
    Client effect listener for Speed Surge ability.
    Manages dynamic camera FOV, cyan motion trail, electric particle aura, and looping rush SFX.
    Location: src/client/AbilityEffects/SpeedSurgeEffect.luau (Syncs to StarterPlayerScripts.Client.AbilityEffects.SpeedSurgeEffect)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local AudioModule = require(Packages:WaitForChild("AudioModule") :: ModuleScript)

local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
local originalFOV = 70
local targetFOV = 82

local activeTrail: Trail? = nil
local activeVfxAttachment: Attachment? = nil

local SpeedSurgeEffect = {
	AbilityId = "speed_surge",

	-- Optional Audio configuration
	StartSound = "SpeedSurgeStart" :: string?, -- Optional whoosh activation SFX
	LoopSound = "SpeedSurgeLoop" :: string?,   -- Optional looping rush SFX
	EndSound = "SpeedSurgeEnd" :: string?,     -- Optional expiration SFX
}

--- Sets up trail attachments on HumanoidRootPart if not present
local function setupTrail(hrp: BasePart): Trail
	local oldTrail = hrp:FindFirstChild("SpeedSurgeTrail") :: Trail?
	if oldTrail then return oldTrail end

	local att0 = hrp:FindFirstChild("SpeedTrailAtt0") :: Attachment?
	if not att0 then
		att0 = Instance.new("Attachment")
		att0.Name = "SpeedTrailAtt0"
		att0.Position = Vector3.new(0, -1.2, 0)
		att0.Parent = hrp
	end

	local att1 = hrp:FindFirstChild("SpeedTrailAtt1") :: Attachment?
	if not att1 then
		att1 = Instance.new("Attachment")
		att1.Name = "SpeedTrailAtt1"
		att1.Position = Vector3.new(0, 1.2, 0)
		att1.Parent = hrp
	end

	local trail = Instance.new("Trail")
	trail.Name = "SpeedSurgeTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.3
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 240, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Enabled = false
	trail.Parent = hrp

	return trail
end

--- Clones and attaches SpeedSurgeVFX template from ReplicatedStorage.Templates.VFX
local function attachVfx(hrp: BasePart): Attachment?
	local templates = ReplicatedStorage:FindFirstChild("Templates")
	local vfxFolder = templates and templates:FindFirstChild("VFX")
	local template = vfxFolder and vfxFolder:FindFirstChild("SpeedSurgeVFX") :: Attachment?

	if not template then
		return nil
	end

	-- Remove any existing duplicate
	local existing = hrp:FindFirstChild("SpeedSurgeVFX")
	if existing then
		existing:Destroy()
	end

	local cloned = template:Clone()
	cloned.Parent = hrp

	-- Enable all emitters and lights inside
	for _, child in ipairs(cloned:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = true
		elseif child:IsA("Light") then
			child.Enabled = true
		end
	end

	return cloned
end

--- Called when Speed Surge starts
function SpeedSurgeEffect.onStart(character: Model, duration: number)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- 1. Camera FOV Boost
	if Camera then
		local fovTween = TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = targetFOV,
		})
		fovTween:Play()
	end

	-- 2. Enable Trail
	activeTrail = setupTrail(hrp)
	if activeTrail then
		activeTrail.Enabled = true
	end

	-- 3. Enable Prefabricated Electric Sparks & Aura from Template
	activeVfxAttachment = attachVfx(hrp)

	-- 4. Play Start Sound (Optional) via AudioModule
	if SpeedSurgeEffect.StartSound then
		AudioModule.playOneShot(SpeedSurgeEffect.StartSound, {
			parent = hrp,
			category = "SFX",
			volume = 0.5,
		})
	end

	-- 5. Play Looping Audio (Optional) via AudioModule
	if SpeedSurgeEffect.LoopSound then
		AudioModule.playLooped("SpeedSurgeLoop", SpeedSurgeEffect.LoopSound, {
			parent = hrp,
			category = "SFX",
			volume = 0.35,
		})
	end
end

--- Called when Speed Surge ends or is cancelled
function SpeedSurgeEffect.onEnd(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?

	-- 1. Reset Camera FOV
	if Camera then
		local fovTween = TweenService:Create(Camera, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = originalFOV,
		})
		fovTween:Play()
	end

	-- 2. Disable Trail
	if activeTrail then
		activeTrail.Enabled = false
		activeTrail = nil
	end

	-- 3. Cleanly Dissipate VFX Emitters
	if activeVfxAttachment then
		local targetVfx = activeVfxAttachment
		activeVfxAttachment = nil

		for _, child in ipairs(targetVfx:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				child.Enabled = false
			elseif child:IsA("Light") then
				child.Enabled = false
			end
		end

		-- Allow in-flight particles to fade out naturally before destroying
		task.delay(1, function()
			if targetVfx and targetVfx.Parent then
				targetVfx:Destroy()
			end
		end)
	end

	-- 4. Stop Looping Audio with Smooth Fade-out via AudioModule
	if SpeedSurgeEffect.LoopSound then
		AudioModule.stopLooped("SpeedSurgeLoop", 0.25)
	end

	-- 5. Play End Sound (Optional) via AudioModule
	if SpeedSurgeEffect.EndSound and hrp then
		AudioModule.playOneShot(SpeedSurgeEffect.EndSound, {
			parent = hrp,
			category = "SFX",
			volume = 0.4,
		})
	end
end

return SpeedSurgeEffect
