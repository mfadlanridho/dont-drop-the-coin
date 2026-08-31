--!nonstrict
--[[
    GuardAIService.luau
    Server orchestrator that binds all Guard and Drone NPC AI models in Workspace to the universal GuardAI framework.
    Location: src/server/Services/GuardAIService.luau
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule"))
local GuardAI = require(Shared:WaitForChild("AI"):WaitForChild("GuardAI"))

local log = Logger.create("Combat")

local Services = script.Parent
local CombatServer = require(Services:WaitForChild("CombatServer"))

local GuardAIService = {}
local activeGuards: { [Model]: any } = {}

-- Bind an NPC Model to GuardAI
local function bindGuardModel(model: Model)
	if activeGuards[model] then return end
	if not model:IsA("Model") then return end

	activeGuards[model] = GuardAI.new(model, {
		onAttackHit = function(victimModel: Model)
			log(string.format("[GuardAIService] %s struck %s!", model.Name, victimModel.Name))
			CombatServer.BumpVictimModel(nil, victimModel)
		end,
	})

	log(string.format("[GuardAIService] Bound GuardAI to model %s", model.Name))
end

-- Initialize Service & Listen to Tags/Folders
function GuardAIService.Init()
	-- Tag: GuardNPC
	for _, instance in ipairs(CollectionService:GetTagged("GuardNPC")) do
		if instance:IsA("Model") then
			bindGuardModel(instance)
		end
	end
	CollectionService:GetInstanceAddedSignal("GuardNPC"):Connect(function(instance)
		if instance:IsA("Model") then
			bindGuardModel(instance)
		end
	end)

	-- Scan Workspace.Hazards for platform models containing guard models
	local hazardsFolder = Workspace:FindFirstChild("Hazards")
	if hazardsFolder then
		for _, descendant in ipairs(hazardsFolder:GetDescendants()) do
			if descendant:IsA("Model") and (descendant.Name:match("Drone") or descendant.Name:match("Guard")) then
				bindGuardModel(descendant)
			end
		end

		hazardsFolder.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("Model") and (descendant.Name:match("Drone") or descendant.Name:match("Guard")) then
				bindGuardModel(descendant)
			end
		end)
	end

	log("[GuardAIService] Initialized Universal Guard AI Service.")
end

return GuardAIService
