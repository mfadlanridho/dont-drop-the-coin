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

local activeVfxAttachment: Attachment? = nil

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

--- Clones and attaches SuperSpringVFX template from ReplicatedStorage.Templates.VFX
local function attachVfx(hrp: BasePart): Attachment?
	local templates = ReplicatedStorage:FindFirstChild("Templates")
	local vfxFolder = templates and templates:FindFirstChild("VFX")
	local template = vfxFolder and vfxFolder:FindFirstChild("SuperSpringVFX") :: Attachment?

	if not template then
		return nil
	end

	-- Remove any existing duplicate
	local existing = hrp:FindFirstChild("SuperSpringVFX")
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

--- Called when Super Spring starts
function SuperSpringEffect.onStart(character: Model, duration: number)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- 1. Trigger Ground Shockwave Ring
	emitJumpShockwave(hrp)

	-- 2. Enable Prefabricated Feet Sparkle Particle Aura from Template
	activeVfxAttachment = attachVfx(hrp)

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

	-- 1. Cleanly Dissipate VFX Emitters
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
