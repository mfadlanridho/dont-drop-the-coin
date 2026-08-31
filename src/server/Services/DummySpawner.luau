--!nonstrict
--[[
    DummySpawner.luau
    Server service that automatically spawns and maintains permanent 3D Target Dummies in the arena with auto-respawning.
    Location: src/server/Services/DummySpawner.luau (Syncs to ServerScriptService.Server.Services.DummySpawner)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule"))

local log = Logger.create("Combat")

local Services = script.Parent
local HitboxService = require(Services:WaitForChild("HitboxService"))

local DUMMY_SPAWN_LOCATIONS = {
	{ Name = "TargetDummy_Center", Position = Vector3.new(0, 4, 16), Color = Color3.fromRGB(255, 120, 0) },
	{ Name = "TargetDummy_Left", Position = Vector3.new(-12, 4, 22), Color = Color3.fromRGB(0, 200, 255) },
	{ Name = "TargetDummy_Right", Position = Vector3.new(12, 4, 22), Color = Color3.fromRGB(255, 50, 200) },
}

local DummySpawner = {}

-- Create a single 3D Target Dummy Model
function DummySpawner.CreateDummy(name: string, spawnPos: Vector3, color: Color3): Model
	local oldModel = Workspace:FindFirstChild(name)
	if oldModel then oldModel:Destroy() end

	local dummy = Instance.new("Model")
	dummy.Name = name

	local dummyHrp = Instance.new("Part")
	dummyHrp.Name = "HumanoidRootPart"
	dummyHrp.Size = Vector3.new(2, 2, 1)
	dummyHrp.Position = spawnPos
	dummyHrp.Anchored = false
	dummyHrp.CanCollide = true
	dummyHrp.Parent = dummy

	local dummyTorso = Instance.new("Part")
	dummyTorso.Name = "UpperTorso"
	dummyTorso.Size = Vector3.new(2, 2.5, 1)
	dummyTorso.Color = color
	dummyTorso.Material = Enum.Material.SmoothPlastic
	dummyTorso.Position = spawnPos + Vector3.new(0, 1.25, 0)
	dummyTorso.Anchored = false
	dummyTorso.CanCollide = true
	dummyTorso.Parent = dummy

	local dummyHead = Instance.new("Part")
	dummyHead.Name = "Head"
	dummyHead.Size = Vector3.new(1.2, 1.2, 1.2)
	dummyHead.Color = Color3.fromRGB(255, 220, 100)
	dummyHead.Position = dummyTorso.Position + Vector3.new(0, 1.8, 0)
	dummyHead.Anchored = false
	dummyHead.CanCollide = true
	dummyHead.Parent = dummy

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = dummy

	-- Welds
	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = dummyHrp
	w1.Part1 = dummyTorso
	w1.Parent = dummyTorso

	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = dummyTorso
	w2.Part1 = dummyHead
	w2.Parent = dummyHead

	dummy.PrimaryPart = dummyHrp
	dummy.Parent = Workspace

	-- Attach full-body HitboxCapsule
	HitboxService.CreateHitbox(dummy)

	log(string.format("Spawned 3D %s at %s", name, tostring(spawnPos)))
	return dummy
end

-- Initialize Service & Maintain Automatic Respawning Dummies
function DummySpawner.Init()
	-- Spawn permanent dummies in Studio & live test servers
	local function spawnAllDummies()
		for _, data in ipairs(DUMMY_SPAWN_LOCATIONS) do
			DummySpawner.CreateDummy(data.Name, data.Position, data.Color)
		end
	end

	spawnAllDummies()

	-- Monitor void falls / respawns every 3 seconds
	task.spawn(function()
		while true do
			task.wait(3)
			for _, data in ipairs(DUMMY_SPAWN_LOCATIONS) do
				local dummy = Workspace:FindFirstChild(data.Name)
				if not dummy then
					DummySpawner.CreateDummy(data.Name, data.Position, data.Color)
				else
					local hrp = dummy:FindFirstChild("HumanoidRootPart") :: Part
					if not hrp or hrp.Position.Y < -20 or (hrp.Position - data.Position).Magnitude > 100 then
						DummySpawner.CreateDummy(data.Name, data.Position, data.Color)
					end
				end
			end
		end
	end)

	log("DummySpawner initialized successfully - 3 permanent target dummies active in arena.")
end

return DummySpawner
