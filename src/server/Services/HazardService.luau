--!nonstrict
--[[
    HazardService.luau
    Central server orchestrator for all environmental hazards and obstacle course mechanics.
    Scans Workspace for "FutureHazardSockets" and "FutureHazards" folders across zones,
    and dynamically binds them to modular OOP hazard controllers.
    Location: src/server/Services/HazardService.luau
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

local log = Logger.create("Hazards")

local Server = script.Parent.Parent
local HazardsFolder = Server:WaitForChild("Hazards")

local RotatingPlatform = require(HazardsFolder:WaitForChild("RotatingPlatform") :: ModuleScript)
local VerticalLift = require(HazardsFolder:WaitForChild("VerticalLift") :: ModuleScript)
local DisappearingPlatform = require(HazardsFolder:WaitForChild("DisappearingPlatform") :: ModuleScript)

local HazardService = {}
local activeHazards: { [Instance]: any } = {}

-- Dispatch a socket to its corresponding hazard OOP handler
local function processSocket(socket: Instance, zoneFolder: Instance)
	if activeHazards[socket] then return end

	local hazardType = socket:GetAttribute("HazardType")
	log(string.format("[HazardService] Processing socket: %s (HazardType: %s) in %s", socket.Name, tostring(hazardType), zoneFolder.Name))

	if hazardType == "RotatingPlatform" and socket:IsA("BasePart") then
		-- Search for nearby route geometry (e.g. CranePlatform)
		local route = zoneFolder:FindFirstChild("Route")
		local targetFolder = route and route:FindFirstChild("CranePlatform")
		if targetFolder then
			local hazardInstance = RotatingPlatform.new(socket, targetFolder)
			if hazardInstance then
				activeHazards[socket] = hazardInstance
			end
		end

	elseif hazardType == "VerticalLift" and socket:IsA("BasePart") then
		local route = zoneFolder:FindFirstChild("Route")
		local targetFolder = route and route:FindFirstChild("CranePlatform")
		if targetFolder then
			local hazardInstance = VerticalLift.new(socket, targetFolder)
			if hazardInstance then
				activeHazards[socket] = hazardInstance
			end
		end

	elseif socket.Name == "DisappearingTileGroup" or hazardType == "DisappearingTile" then
		-- Pointers to Route folder (e.g. Route.DisappearingTiles)
		local pathFolder = socket:GetAttribute("PathFolder")
		local targetContainer: Instance? = nil
		if typeof(pathFolder) == "string" then
			-- Resolve dotted path relative to zoneFolder (e.g. "Route.DisappearingTiles")
			local current: Instance? = zoneFolder
			for segment in string.gmatch(pathFolder, "[^.]+") do
				if current then
					current = current:FindFirstChild(segment)
				end
			end
			targetContainer = current
		end

		if targetContainer then
			for _, tile in ipairs(targetContainer:GetChildren()) do
				CollectionService:AddTag(tile, "Hazard_DisappearingPlatform")
			end
		end
	end
end

-- Scan and initialize all sockets in the game
local function scanAllSockets()
	for _, desc in ipairs(Workspace:GetChildren()) do
		if desc.Name:match("^Zone%d+") then
			local zoneFolder = desc
			-- Check both naming conventions (FutureHazardSockets and FutureHazards)
			local socketsFolder = zoneFolder:FindFirstChild("FutureHazardSockets") or zoneFolder:FindFirstChild("FutureHazards")
			if socketsFolder then
				for _, socket in ipairs(socketsFolder:GetChildren()) do
					processSocket(socket, zoneFolder)
				end
			end
		end
	end
end

local TAG_DISAPPEARING = "Hazard_DisappearingPlatform"

local function bindDisappearingPlatform(inst: Instance)
	if activeHazards[inst] then return end
	local success, platformInstance = pcall(function()
		return DisappearingPlatform.new(inst)
	end)
	if success and platformInstance then
		activeHazards[inst] = platformInstance
		log(string.format("[HazardService] Bound tagged platform: %s", inst:GetFullName()))

		local conn: RBXScriptConnection?
		conn = inst.AncestryChanged:Connect(function(_, parent)
			if not parent then
				if conn then
					conn:Disconnect()
					conn = nil
				end
				if activeHazards[inst] then
					if typeof(activeHazards[inst].destroy) == "function" then
						activeHazards[inst]:destroy()
					end
					activeHazards[inst] = nil
				end
			end
		end)
	end
end

function HazardService.Init()
	log("[HazardService] Initializing HazardService...")
	scanAllSockets()

	-- Also support any standalone platforms tagged with CollectionService
	for _, inst in ipairs(CollectionService:GetTagged(TAG_DISAPPEARING)) do
		task.spawn(bindDisappearingPlatform, inst)
	end
	CollectionService:GetInstanceAddedSignal(TAG_DISAPPEARING):Connect(bindDisappearingPlatform)

	log("[HazardService] HazardService initialization complete!")
end

function HazardService.GetActiveHazards()
	return activeHazards
end

return HazardService
