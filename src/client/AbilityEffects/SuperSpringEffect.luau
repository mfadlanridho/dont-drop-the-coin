--!strict
--[[
    SuperSpringEffect.luau
    Client effect listener for Super Spring ability.
    Manages jump shockwave ring VFX, emerald feet sparkle aura, and looping spring hum SFX.
    Location: src/client/AbilityEffects/SuperSpringEffect.luau (Syncs to StarterPlayerScripts.Client.AbilityEffects.SuperSpringEffect)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local AudioModule = require(Packages:WaitForChild("AudioModule") :: ModuleScript)

local activeEmitter: ParticleEmitter? = nil

local SuperSpringEffect = {
	AbilityId = "super_spring",

	-- Optional Audio configuration
	StartSound = "SuperSpringStart" :: string?, -- Optional activation jump SFX
	LoopSound = "SuperSpringLoop" :: string?,   -- Optional looping spring hum SFX
	EndSound = "SuperSpringEnd" :: string?,     -- Optional expiration SFX
}

--- Emits an emerald upward jump ring shockwave at character feet
local function emitJumpShockwave(hrp: BasePart)
	local ring = Instance.new("Part")
	ring.Name = "JumpShockwave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(0, 255, 120)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Transparency = 0.2
	ring.Parent = Workspace

	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(ring, tweenInfo, {
		Size = Vector3.new(0.1, 14, 14),
		Transparency = 1,
	})
	tween:Play()
	task.delay(0.45, function()
		ring:Destroy()
	end)
end

--- Sets up emerald sparkles emitter on character feet
local function setupFeetEmitter(hrp: BasePart): ParticleEmitter
	local old = hrp:FindFirstChild("SuperSpringSparkles") :: ParticleEmitter?
	if old then return old end

	local att = hrp:FindFirstChild("SpringFeetAtt") :: Attachment?
	if not att then
		att = Instance.new("Attachment")
		att.Name = "SpringFeetAtt"
		att.Position = Vector3.new(0, -2, 0)
		att.Parent = hrp
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SuperSpringSparkles"
	emitter.Rate = 22
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Speed = NumberRange.new(2, 6)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 140)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 255, 200)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 0.9
	emitter.LightInfluence = 0
	emitter.Enabled = false
	emitter.Parent = att

	return emitter
end

--- Called when Super Spring starts
function SuperSpringEffect.onStart(character: Model, duration: number)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- 1. Trigger Ground Shockwave Ring
	emitJumpShockwave(hrp)

	-- 2. Enable Feet Sparkle Particle Aura
	activeEmitter = setupFeetEmitter(hrp)
	if activeEmitter then
		activeEmitter.Enabled = true
	end

	-- 3. Play Start Sound (Optional) via AudioModule
	if SuperSpringEffect.StartSound then
		AudioModule.playOneShot(SuperSpringEffect.StartSound, {
			parent = hrp,
			category = "SFX",
			volume = 0.45,
			pitch = 1.25,
		})
	end

	-- 4. Play Looping Spring Hum (Optional) via AudioModule
	if SuperSpringEffect.LoopSound then
		AudioModule.playLooped("SuperSpringLoop", SuperSpringEffect.LoopSound, {
			parent = hrp,
			category = "SFX",
			volume = 0.3,
			pitch = 1.35,
		})
	end
end

--- Called when Super Spring ends or is cancelled
function SuperSpringEffect.onEnd(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?

	-- 1. Disable Feet Sparkle Particle Aura
	if activeEmitter then
		activeEmitter.Enabled = false
		activeEmitter = nil
	end

	-- 2. Stop Looping Audio with Smooth Fade-out via AudioModule
	if SuperSpringEffect.LoopSound then
		AudioModule.stopLooped("SuperSpringLoop", 0.25)
	end

	-- 3. Play End Sound (Optional) via AudioModule
	if SuperSpringEffect.EndSound and hrp then
		AudioModule.playOneShot(SuperSpringEffect.EndSound, {
			parent = hrp,
			category = "SFX",
			volume = 0.35,
		})
	end
end

return SuperSpringEffect
