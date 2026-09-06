--!nonstrict
--[[
    DisappearingPlatformService.luau
    Dedicated server orchestrator for Zone 3 Disappearing Platforms.
    Monitors Workspace.Hazards.DisappearingPlatforms and CollectionService tags ("Hazard_DisappearingPlatform")
    to instantiate and manage DisappearingPlatform OOP instances.
    Location: src/server/Services/DisappearingPlatformService.luau
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

local log = Logger.create("Hazards")

local Server = script.Parent.Parent
local HazardsFolder = Server:WaitForChild("Hazards")
local DisappearingPlatform = require(HazardsFolder:WaitForChild("DisappearingPlatform") :: ModuleScript)

local DisappearingPlatformService = {}
local activePlatforms: { [Instance]: any } = {}

-- Bind an instance (Part or Model) to DisappearingPlatform OOP
local function bindPlatform(instance: Instance)
	if activePlatforms[instance] then return end

	local success, platformInstance = pcall(function()
		return DisappearingPlatform.new(instance)
	end)

	if success and platformInstance then
		activePlatforms[instance] = platformInstance
		log(string.format("[DisappearingPlatformService] Bound platform: %s", instance:GetFullName()))

		-- Auto-destroy when removed from game hierarchy
		local conn: RBXScriptConnection?
		conn = instance.AncestryChanged:Connect(function(_, parent)
			if not parent then
				if conn then
					conn:Disconnect()
					conn = nil
				end
				if activePlatforms[instance] then
					if typeof(activePlatforms[instance].destroy) == "function" then
						activePlatforms[instance]:destroy()
					end
					activePlatforms[instance] = nil
					log(string.format("[DisappearingPlatformService] Cleaned up platform: %s", instance.Name))
				end
			end
		end)
	else
		warn(string.format("[DisappearingPlatformService] Failed to bind %s: %s", instance.Name, tostring(platformInstance)))
	end
end

-- Public API: Retrieve active OOP instance for a given part/model
function DisappearingPlatformService.GetPlatform(instance: Instance): any?
	return activePlatforms[instance]
end

-- Initialize Service
function DisappearingPlatformService.Init()
	-- 1. Ensure Workspace.Hazards.DisappearingPlatforms folder hierarchy exists
	local hazardsFolder = Workspace:FindFirstChild("Hazards")
	if not hazardsFolder then
		hazardsFolder = Instance.new("Folder")
		hazardsFolder.Name = "Hazards"
		hazardsFolder.Parent = Workspace
	end

	local subfolder = hazardsFolder:FindFirstChild("DisappearingPlatforms")
	if not subfolder then
		subfolder = Instance.new("Folder")
		subfolder.Name = "DisappearingPlatforms"
		subfolder.Parent = hazardsFolder
	end

	-- Bind existing children & listen for runtime additions
	for _, child in ipairs(subfolder:GetChildren()) do
		bindPlatform(child)
	end
	subfolder.ChildAdded:Connect(bindPlatform)

	-- 2. CollectionService Tag Support (Hazard_DisappearingPlatform)
	for _, inst in ipairs(CollectionService:GetTagged("Hazard_DisappearingPlatform")) do
		bindPlatform(inst)
	end

	CollectionService:GetInstanceAddedSignal("Hazard_DisappearingPlatform"):Connect(bindPlatform)
	CollectionService:GetInstanceRemovedSignal("Hazard_DisappearingPlatform"):Connect(function(inst)
		local platform = activePlatforms[inst]
		if platform then
			if typeof(platform.destroy) == "function" then
				platform:destroy()
			end
			activePlatforms[inst] = nil
		end
	end)

	log("[DisappearingPlatformService] Initialized Disappearing Platform Service.")
end

return DisappearingPlatformService
