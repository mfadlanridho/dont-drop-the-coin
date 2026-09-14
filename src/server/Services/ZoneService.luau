--!strict
--[[
    ZoneService.luau
    Master server service acting as the single source of truth for Tower Zones and walkable ZoneFloor arenas.
    Uses SignalModule to publish ZoneFloorDiscovered events to decoupled listeners (CoinSpawner, GuardAIService, etc.).
    Location: src/server/Services/ZoneService.luau (Syncs to ServerScriptService.Server.Services.ZoneService)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local SignalModule = require(Packages:WaitForChild("SignalModule"))

export type ZoneData = {
	ZoneModel: Model,
	FloorSlab: BasePart,
	ZoneTier: number,
	SurfaceCenter: Vector3,
	UpwardNormal: Vector3,
	TopSurfaceY: number,
}

local ZoneService = {}
local discoveredZones: { [number]: ZoneData } = {}

-- Event: Fires when a valid ZoneFloor slab is discovered and validated
ZoneService.ZoneFloorDiscovered = SignalModule.new() :: SignalModule.Signal<ZoneData>

--- Computes dot products to identify which face of the part is facing upwards into the sky
local function getUpwardFaceData(part: BasePart)
	local cf = part.CFrame
	local size = part.Size

	local faces = {
		{
			normal = cf.UpVector,
			normalExtent = size.Y / 2,
			tangentU = cf.RightVector,
			extentU = size.X,
			tangentV = cf.LookVector,
			extentV = size.Z,
		},
		{
			normal = -cf.UpVector,
			normalExtent = size.Y / 2,
			tangentU = cf.RightVector,
			extentU = size.X,
			tangentV = cf.LookVector,
			extentV = size.Z,
		},
		{
			normal = cf.RightVector,
			normalExtent = size.X / 2,
			tangentU = cf.UpVector,
			extentU = size.Y,
			tangentV = cf.LookVector,
			extentV = size.Z,
		},
		{
			normal = -cf.RightVector,
			normalExtent = size.X / 2,
			tangentU = cf.UpVector,
			extentU = size.Y,
			tangentV = cf.LookVector,
			extentV = size.Z,
		},
		{
			normal = cf.LookVector,
			normalExtent = size.Z / 2,
			tangentU = cf.RightVector,
			extentU = size.X,
			tangentV = cf.UpVector,
			extentV = size.Y,
		},
		{
			normal = -cf.LookVector,
			normalExtent = size.Z / 2,
			tangentU = cf.RightVector,
			extentU = size.X,
			tangentV = cf.UpVector,
			extentV = size.Y,
		},
	}

	local bestFace = faces[1]
	local maxDot = -math.huge

	for _, face in ipairs(faces) do
		local dot = face.normal:Dot(Vector3.yAxis)
		if dot > maxDot then
			maxDot = dot
			bestFace = face
		end
	end

	return bestFace
end

--- Finds the primary walkable floor slab within a ZoneFloor folder (filters out neon trims/accents)
local function findPrimaryFloorSlab(floorFolder: Instance): BasePart?
	local candidates: { BasePart } = {}
	for _, child in ipairs(floorFolder:GetChildren()) do
		if child:IsA("BasePart") and child.CanCollide then
			table.insert(candidates, child)
		end
	end

	if #candidates == 0 then
		return nil
	elseif #candidates == 1 then
		return candidates[1]
	end

	-- Prefer non-neon materials to avoid selecting decorative underglow/trim
	local nonNeonCandidates: { BasePart } = {}
	for _, part in ipairs(candidates) do
		if part.Material ~= Enum.Material.Neon then
			table.insert(nonNeonCandidates, part)
		end
	end

	local pool = if #nonNeonCandidates > 0 then nonNeonCandidates else candidates

	-- Pick candidate with the highest upward surface elevation
	local bestPart = pool[1]
	local bestTopY = -math.huge
	for _, part in ipairs(pool) do
		local face = getUpwardFaceData(part)
		local topY = part.Position.Y + (face.normal.Y * face.normalExtent)
		if topY > bestTopY then
			bestTopY = topY
			bestPart = part
		end
	end

	return bestPart
end

--- Validates and processes a Zone model, extracting tier and primary floor slab
local function processZoneModel(model: Instance)
	if not (model:IsA("Model") or model:IsA("Folder")) then return end

	local tierStr = model.Name:match("^Zone(%d+)")
	if not tierStr then return end

	local zoneTier = tonumber(tierStr)
	if not zoneTier or discoveredZones[zoneTier] then return end

	local floorFolder = model:FindFirstChild("ZoneFloor")
	if not floorFolder then return end

	local primarySlab = findPrimaryFloorSlab(floorFolder)
	if not primarySlab then return end

	local face = getUpwardFaceData(primarySlab)
	local topY = primarySlab.Position.Y + (face.normal.Y * face.normalExtent)
	local surfaceCenter = primarySlab.Position + (face.normal * face.normalExtent)

	local zoneData: ZoneData = {
		ZoneModel = model :: Model,
		FloorSlab = primarySlab,
		ZoneTier = zoneTier,
		SurfaceCenter = surfaceCenter,
		UpwardNormal = face.normal,
		TopSurfaceY = topY,
	}

	discoveredZones[zoneTier] = zoneData
	print(string.format("[ZoneService] Discovered %s (Tier %d) -> Primary Slab: %s [TopY: %.1f]", model.Name, zoneTier, primarySlab.Name, topY))

	ZoneService.ZoneFloorDiscovered:Fire(zoneData)
end

--- Replay-safe subscription helper: invokes callback for all existing zones, and listens for future ones
function ZoneService.OnZoneFloorDiscovered(callback: (ZoneData) -> ()): SignalModule.Connection
	-- Replay all currently discovered zones
	for _, zoneData in pairs(discoveredZones) do
		task.spawn(callback, zoneData)
	end

	-- Connect for any future additions
	return ZoneService.ZoneFloorDiscovered:Connect(callback)
end

--- Returns a table of all currently discovered zones mapped by Tier number
function ZoneService.GetZones(): { [number]: ZoneData }
	return table.clone(discoveredZones)
end

--- Returns the ZoneData for a specific tier if discovered
function ZoneService.GetZoneByTier(tier: number): ZoneData?
	return discoveredZones[tier]
end

--- Resets cached state (useful for live-reload / tests)
function ZoneService.Cleanup()
	table.clear(discoveredZones)
	ZoneService.ZoneFloorDiscovered:DisconnectAll()
end

--- Initializes the service by scanning Workspace for existing zones and listening for additions
function ZoneService.Init()
	-- Initial scan of Workspace
	for _, child in ipairs(Workspace:GetChildren()) do
		processZoneModel(child)
	end

	-- Dynamic listener for any zones added at runtime
	Workspace.ChildAdded:Connect(function(child)
		processZoneModel(child)
	end)

	local count = 0
	for _ in pairs(discoveredZones) do count += 1 end
	print(string.format("[ZoneService] Initialized. Total zones discovered: %d", count))
end

return ZoneService
