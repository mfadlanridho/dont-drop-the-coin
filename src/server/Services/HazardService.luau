--!strict
--[[
    HazardService.luau
    Lightweight server orchestrator for environmental hazards.
    Location: src/server/Services/HazardService.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared:WaitForChild("Utils"):WaitForChild("Logger") :: ModuleScript)

local log = Logger.create("Combat")

local HazardsFolder = script.Parent.Parent:WaitForChild("Hazards")
local PistonCrusher = require(HazardsFolder:WaitForChild("PistonCrusher") :: ModuleScript)
local PendulumObstacle = require(HazardsFolder:WaitForChild("PendulumObstacle") :: ModuleScript)
local DisappearingPlatform = require(HazardsFolder:WaitForChild("DisappearingPlatform") :: ModuleScript)

local HazardService = {}
local activeInstances: { [Instance]: any } = {}

-- Bind Piston Hazard
local function bindPiston(part: Instance)
	if not part:IsA("BasePart") or activeInstances[part] then return end
	activeInstances[part] = PistonCrusher.new(part)
	log(string.format("[HazardService] Bound PistonCrusher: %s", part.Name))
end

-- Bind Pendulum Hazard
local function bindPendulum(part: Instance)
	if not part:IsA("BasePart") or activeInstances[part] then return end
	activeInstances[part] = PendulumObstacle.new(part)
	log(string.format("[HazardService] Bound PendulumObstacle: %s", part.Name))
end

-- Bind Disappearing Platform Hazard
local function bindDisappearingPlatform(part: Instance)
	if not part:IsA("BasePart") or activeInstances[part] then return end
	activeInstances[part] = DisappearingPlatform.new(part)
	log(string.format("[HazardService] Bound DisappearingPlatform: %s", part.Name))
end

-- Monitor Subfolder for Child Parts
local function setupSubfolder(parentFolder: Instance, folderName: string, bindFunc: (Instance) -> ())
	local subfolder = parentFolder:FindFirstChild(folderName)
	if not subfolder then
		subfolder = Instance.new("Folder")
		subfolder.Name = folderName
		subfolder.Parent = parentFolder
	end

	for _, child in ipairs(subfolder:GetChildren()) do
		bindFunc(child)
	end
	subfolder.ChildAdded:Connect(bindFunc)
end

-- Initialize Service & Scan Subfolders inside Workspace.Hazards
function HazardService.Init()
	local mainHazardsFolder = Workspace:FindFirstChild("Hazards")
	if not mainHazardsFolder then
		mainHazardsFolder = Instance.new("Folder")
		mainHazardsFolder.Name = "Hazards"
		mainHazardsFolder.Parent = Workspace
	end

	setupSubfolder(mainHazardsFolder, "Pistons", bindPiston)
	setupSubfolder(mainHazardsFolder, "Pendulums", bindPendulum)
	setupSubfolder(mainHazardsFolder, "DisappearingPlatforms", bindDisappearingPlatform)

	log("[HazardService] Initialized environmental hazard system.")
end

return HazardService
