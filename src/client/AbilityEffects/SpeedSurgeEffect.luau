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
local activeEmitter: ParticleEmitter? = nil

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

--- Sets up electric sparks particle emitter on HumanoidRootPart
local function setupEmitter(hrp: BasePart): ParticleEmitter
	local old = hrp:FindFirstChild("SpeedSurgeSparks") :: ParticleEmitter?
	if old then return old end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SpeedSurgeSparks"
	emitter.Rate = 25
	emitter.Lifetime = NumberRange.new(0.2, 0.45)
	emitter.Speed = NumberRange.new(3, 7)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 140, 255)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Enabled = false
	emitter.Parent = hrp

	return emitter
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

	-- 3. Enable Electric Sparks Particle Aura
	activeEmitter = setupEmitter(hrp)
	if activeEmitter then
		activeEmitter.Enabled = true
	end

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

	-- 3. Disable Particle Aura
	if activeEmitter then
		activeEmitter.Enabled = false
		activeEmitter = nil
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
