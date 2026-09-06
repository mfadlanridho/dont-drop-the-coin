--!nonstrict
--[[
    PistonCrusherService.luau
    Dedicated server orchestrator for Zone 2 mechanical Piston Crushers.
    Streaming-native CollectionService enforcement ("Hazard_Piston") with auto-tagging
    for Workspace.Hazards.Pistons.
    Location: src/server/Services/PistonCrusherService.luau
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

local log = Logger.create("Hazards")

local Server = script.Parent.Parent
local HazardsFolder = Server:WaitForChild("Hazards")
local PistonCrusher = require(HazardsFolder:WaitForChild("PistonCrusher") :: ModuleScript)

local PistonCrusherService = {}
local activePistons: { [Instance]: any } = {}

local TAG_NAME = "Hazard_Piston"

-- Bind an instance (Part or Model) to PistonCrusher OOP
local function bindPiston(instance: Instance)
	if activePistons[instance] then return end

	local success, pistonInstance = pcall(function()
		return PistonCrusher.new(instance)
	end)

	if success and pistonInstance then
		activePistons[instance] = pistonInstance
		log(string.format("[PistonCrusherService] Bound piston: %s", instance:GetFullName()))

		-- Auto-cleanup on removal
		local conn: RBXScriptConnection?
		conn = instance.AncestryChanged:Connect(function(_, parent)
			if not parent then
				if conn then
					conn:Disconnect()
					conn = nil
				end
				if activePistons[instance] then
					if typeof(activePistons[instance].destroy) == "function" then
						activePistons[instance]:destroy()
					end
					activePistons[instance] = nil
					log(string.format("[PistonCrusherService] Cleaned up piston: %s", instance.Name))
				end
			end
		end)
	else
		warn(string.format("[PistonCrusherService] Failed to bind %s: %s", instance.Name, tostring(pistonInstance)))
	end
end

-- Public API: Retrieve active OOP instance
function PistonCrusherService.GetPiston(instance: Instance): any?
	return activePistons[instance]
end

-- Initialize Service
function PistonCrusherService.Init()
	-- 1. Primary: 100% Streaming-Native CollectionService Enforcement
	for _, inst in ipairs(CollectionService:GetTagged(TAG_NAME)) do
		task.spawn(bindPiston, inst)
	end

	CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(bindPiston)
	CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(function(inst)
		local piston = activePistons[inst]
		if piston then
			if typeof(piston.destroy) == "function" then
				piston:destroy()
			end
			activePistons[inst] = nil
		end
	end)

	-- 2. Server Convenience: Auto-tag any part placed into Workspace.Hazards.Pistons
	local hazardsFolder = Workspace:FindFirstChild("Hazards")
	local subfolder = hazardsFolder and hazardsFolder:FindFirstChild("Pistons")
	if subfolder then
		local function autoTag(child: Instance)
			if not CollectionService:HasTag(child, TAG_NAME) then
				CollectionService:AddTag(child, TAG_NAME)
			end
		end

		for _, child in ipairs(subfolder:GetChildren()) do
			autoTag(child)
		end
		subfolder.ChildAdded:Connect(autoTag)
	end

	log("[PistonCrusherService] Initialized streaming-native Piston Crusher Service.")
end

return PistonCrusherService
