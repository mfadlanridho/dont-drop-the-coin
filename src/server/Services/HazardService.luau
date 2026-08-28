--!strict
--[[
    HazardService.luau
    Lightweight server orchestrator that binds physical Workspace.Hazards subfolders (Pistons, Pendulums, DisappearingPlatforms, Drones) to modular hazard OOP classes.
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
local GlitchDroneAI = require(HazardsFolder:WaitForChild("GlitchDroneAI") :: ModuleScript)

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

-- Bind Glitch Drone AI Hazard
local function bindGlitchDrone(instance: Instance)
	if activeInstances[instance] then return end
	if instance:IsA("Model") then
		activeInstances[instance] = GlitchDroneAI.new(instance)
		log(string.format("[HazardService] Bound GlitchDroneAI: %s", instance.Name))
	end
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

-- Initialize Service & Scan Subfolders
function HazardService.Init()
	local mainHazardsFolder = Workspace:FindFirstChild("Hazards")
	if not mainHazardsFolder then
		mainHazardsFolder = Instance.new("Folder")
		mainHazardsFolder.Name = "Hazards"
		mainHazardsFolder.Parent = Workspace
	end

	-- Subfolders: Workspace.Hazards.Pistons, Pendulums, DisappearingPlatforms, Drones
	setupSubfolder(mainHazardsFolder, "Pistons", bindPiston)
	setupSubfolder(mainHazardsFolder, "Pendulums", bindPendulum)
	setupSubfolder(mainHazardsFolder, "DisappearingPlatforms", bindDisappearingPlatform)
	setupSubfolder(mainHazardsFolder, "Drones", bindGlitchDrone)

	-- Fallback scan for loose parts in main Hazards folder
	for _, child in ipairs(mainHazardsFolder:GetChildren()) do
		if child:IsA("BasePart") and not child.Parent:IsA("Folder") or child.Parent == mainHazardsFolder then
			if child.Name:match("Piston") then
				bindPiston(child)
			elseif child.Name:match("Pendulum") then
				bindPendulum(child)
			elseif child.Name:match("Disappearing") then
				bindDisappearingPlatform(child)
			end
		end
	end

	log("[HazardService] Initialized subfolder hazard system (Pistons, Pendulums, DisappearingPlatforms, Drones).")
end

return HazardService
