--!nonstrict
--[[
    VerticalLift.luau
    Modular OOP component for vertical elevator platforms (e.g. Zone 2 CranePlatform lift deck).
    Uses a PrismaticConstraint in Servo mode or physical kinematic positioning,
    preserving character physics and friction as players ride up and down.
    Location: src/server/Hazards/VerticalLift.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Logger = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

local log = Logger.create("Hazards")

local VerticalLift = {}
VerticalLift.__index = VerticalLift

export type VerticalLiftInstance = {
	socket: BasePart,
	folder: Instance,
	mainDeck: BasePart,
	liftParts: { BasePart },
	constraint: PrismaticConstraint?,
	travelUp: number,
	cycleSpeed: number,
	pauseTime: number,
	isRunning: boolean,
	isDestroyed: boolean,
	destroy: (self: VerticalLiftInstance) -> (),
}

function VerticalLift.new(socket: BasePart, modelOrFolder: Instance): VerticalLiftInstance?
	-- Find the primary lift surface part (e.g. CP_LiftDeck_Deck)
	local mainDeck: BasePart? = modelOrFolder:FindFirstChild("CP_LiftDeck_Deck") :: any
	if not mainDeck then
		for _, child in ipairs(modelOrFolder:GetChildren()) do
			if child:IsA("BasePart") and child.Name:match("Deck") then
				mainDeck = child
				break
			end
		end
	end

	if not mainDeck then
		warn(string.format("[VerticalLift] No Deck part found in %s for socket %s", modelOrFolder.Name, socket.Name))
		return nil
	end

	local self = setmetatable({}, VerticalLift) :: any
	self.socket = socket
	self.folder = modelOrFolder
	self.mainDeck = mainDeck
	self.liftParts = {}
	self.isRunning = true
	self.isDestroyed = false

	-- Read TravelUp from socket attributes (defaults to 8 studs if not set)
	local travelAttr = socket:GetAttribute("TravelUp")
	self.travelUp = typeof(travelAttr) == "number" and travelAttr or 8
	self.cycleSpeed = 4 -- Studs per second
	self.pauseTime = 2.0 -- Seconds at top and bottom

	-- Collect all lift deck pieces and chains that move with the elevator
	for _, child in ipairs(modelOrFolder:GetChildren()) do
		if child:IsA("BasePart") and child ~= mainDeck and (child.Name:match("^CP_LiftDeck") or child.Name:match("^CP_Chain")) then
			table.insert(self.liftParts, child)
		end
	end

	-- Weld all moving lift parts to mainDeck
	for _, part in ipairs(self.liftParts) do
		part.Anchored = false
		part.CanCollide = true
		part.Massless = false

		local weld = Instance.new("WeldConstraint")
		weld.Name = "VL_Weld_" .. part.Name
		weld.Part0 = mainDeck
		weld.Part1 = part
		weld.Parent = mainDeck
	end

	-- Anchor of mainDeck will be managed via PrismaticConstraint
	-- We create a reference anchor part at the base
	local anchorPart = Instance.new("Part")
	anchorPart.Name = "VL_LiftBaseAnchor"
	anchorPart.Size = Vector3.new(1, 1, 1)
	anchorPart.CFrame = mainDeck.CFrame
	anchorPart.Transparency = 1
	anchorPart.CanCollide = false
	anchorPart.CanTouch = false
	anchorPart.CanQuery = false
	anchorPart.Anchored = true
	anchorPart.Parent = modelOrFolder

	local att0 = Instance.new("Attachment")
	att0.Name = "VL_Att0"
	att0.Parent = anchorPart
	att0.WorldPosition = mainDeck.Position
	att0.WorldAxis = Vector3.new(0, 1, 0)

	local att1 = Instance.new("Attachment")
	att1.Name = "VL_Att1"
	att1.Parent = mainDeck
	att1.WorldPosition = mainDeck.Position
	att1.WorldAxis = Vector3.new(0, 1, 0)

	-- Use smooth kinematic simulation with AssemblyLinearVelocity so characters stay grounded and ride smoothly
	local RunService = game:GetService("RunService")
	local startCFrame = mainDeck.CFrame
	local basePos = mainDeck.Position
	local targetTopPos = basePos + Vector3.new(0, self.travelUp, 0)
	mainDeck.Anchored = true

	local state = "Ascending" -- "Ascending", "TopPause", "Descending", "BottomPause"
	local pauseTimer = 0

	local connection: RBXScriptConnection?
	connection = RunService.Stepped:Connect(function(_, dt)
		if not self.isRunning or self.isDestroyed or not mainDeck.Parent then
			if connection then
				connection:Disconnect()
				connection = nil
			end
			return
		end

		if state == "Ascending" then
			local currentY = mainDeck.Position.Y
			local targetY = targetTopPos.Y
			if currentY >= targetY - 0.05 then
				mainDeck.CFrame = startCFrame + Vector3.new(0, self.travelUp, 0)
				mainDeck.AssemblyLinearVelocity = Vector3.zero
				state = "TopPause"
				pauseTimer = 0
			else
				local newY = math.min(currentY + self.cycleSpeed * dt, targetY)
				mainDeck.CFrame = startCFrame + Vector3.new(0, newY - basePos.Y, 0)
				mainDeck.AssemblyLinearVelocity = Vector3.new(0, self.cycleSpeed, 0)
			end

		elseif state == "TopPause" then
			mainDeck.AssemblyLinearVelocity = Vector3.zero
			pauseTimer += dt
			if pauseTimer >= self.pauseTime then
				state = "Descending"
			end

		elseif state == "Descending" then
			local currentY = mainDeck.Position.Y
			local targetY = basePos.Y
			if currentY <= targetY + 0.05 then
				mainDeck.CFrame = startCFrame
				mainDeck.AssemblyLinearVelocity = Vector3.zero
				state = "BottomPause"
				pauseTimer = 0
			else
				local newY = math.max(currentY - self.cycleSpeed * dt, targetY)
				mainDeck.CFrame = startCFrame + Vector3.new(0, newY - basePos.Y, 0)
				mainDeck.AssemblyLinearVelocity = Vector3.new(0, -self.cycleSpeed, 0)
			end

		elseif state == "BottomPause" then
			mainDeck.AssemblyLinearVelocity = Vector3.zero
			pauseTimer += dt
			if pauseTimer >= self.pauseTime then
				state = "Ascending"
			end
		end
	end)

	self.steppedConnection = connection

	log(string.format("[VerticalLift] Successfully initialized for socket %s (TravelUp: %.1f)", socket.Name, self.travelUp))
	return self
end

function VerticalLift:destroy()
	if self.isDestroyed then return end
	self.isDestroyed = true
	self.isRunning = false

	if self.steppedConnection then
		self.steppedConnection:Disconnect()
		self.steppedConnection = nil
	end

	if self.constraint then
		self.constraint:Destroy()
	end

	if self.mainDeck and self.mainDeck.Parent then
		self.mainDeck.Anchored = true
		for _, child in ipairs(self.mainDeck:GetChildren()) do
			if child:IsA("WeldConstraint") and child.Name:match("^VL_Weld") then
				child:Destroy()
			end
		end
	end

	for _, part in ipairs(self.liftParts) do
		if part and part.Parent then
			part.Anchored = true
		end
	end

	local anchorPart = self.folder:FindFirstChild("VL_LiftBaseAnchor")
	if anchorPart then
		anchorPart:Destroy()
	end
end

return VerticalLift
