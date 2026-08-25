local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DebugGuiController = require(script.Parent:WaitForChild("DebugGuiController"))

local localPlayer = Players.LocalPlayer
local UPDATE_INTERVAL_SECONDS = 0.2

local PlayerFSM = nil
task.spawn(function()
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
	local utilsFolder = sharedFolder and sharedFolder:WaitForChild("Utils", 5)
	if utilsFolder and utilsFolder:FindFirstChild("PlayerFSM") then
		PlayerFSM = require(utilsFolder:FindFirstChild("PlayerFSM"))
	end
end)

local function formatBoolean(value)
	return if value then "true" else "false"
end

local function formatNumber(value)
	return string.format("%.1f", value)
end

local function formatVector3(vector)
	return string.format("(%.1f, %.1f, %.1f)", vector.X, vector.Y, vector.Z)
end

local function getCharacter()
	return localPlayer.Character
end

local function getHumanoid(character)
	if character == nil then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		return humanoid
	end

	return nil
end

local function getRootPart(character)
	if character == nil then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart ~= nil and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function updateDebugValues(fps)
	local character = getCharacter()
	local humanoid = getHumanoid(character)
	local rootPart = getRootPart(character)

	-- Session Panel
	DebugGuiController.setValue("session", "Studio", formatBoolean(RunService:IsStudio()), "Session", 10)
	DebugGuiController.setValue("session", "Player", localPlayer.Name, "Session", 10)
	DebugGuiController.setValue("session", "UserId", localPlayer.UserId, "Session", 10)
	DebugGuiController.setValue("session", "PlaceId", game.PlaceId, "Session", 10)
	DebugGuiController.setValue("session", "JobId", if game.JobId == "" then "Studio" else string.sub(game.JobId, 1, 12), "Session", 10)
	DebugGuiController.setValue("session", "FPS", formatNumber(fps), "Session", 10)

	-- Player State Panel
	local fsmState = if PlayerFSM then PlayerFSM.GetState(localPlayer) else "Unknown"
	local humanoidState = if humanoid ~= nil then humanoid:GetState().Name else "None"
	local canDash = if PlayerFSM then formatBoolean(PlayerFSM.CanDash(localPlayer)) else "N/A"
	local canBeBumped = if PlayerFSM then formatBoolean(PlayerFSM.CanBeBumped(localPlayer)) else "N/A"

	DebugGuiController.setValue("state", "FSMState", fsmState, "Player State", 15, "FSM State", 1)
	DebugGuiController.setValue("state", "HumanoidState", humanoidState, "Player State", 15, "Physics State", 2)
	DebugGuiController.setValue("state", "CanDash", canDash, "Player State", 15, "Can Dash?", 3)
	DebugGuiController.setValue("state", "CanBeBumped", canBeBumped, "Player State", 15, "Can Be Bumped?", 4)

	-- Character Panel
	DebugGuiController.setValue("character", "Loaded", formatBoolean(character ~= nil), "Character", 20)
	DebugGuiController.setValue("character", "Name", if character ~= nil then character.Name else "None", "Character", 20)
	DebugGuiController.setValue("character", "RootPosition", if rootPart ~= nil then formatVector3(rootPart.Position) else "None", "Character", 20)
	DebugGuiController.setValue(
		"character",
		"MoveDirection",
		if humanoid ~= nil then formatVector3(humanoid.MoveDirection) else "None",
		"Character",
		20
	)
	DebugGuiController.setValue(
		"character",
		"MoveMagnitude",
		if humanoid ~= nil then formatNumber(humanoid.MoveDirection.Magnitude) else "0.0",
		"Character",
		20
	)
	DebugGuiController.setValue(
		"character",
		"FloorMaterial",
		if humanoid ~= nil then humanoid.FloorMaterial.Name else "None",
		"Character",
		20
	)
end

if not DebugGuiController.start() then
	return
end

local elapsed = 0
local frameCount = 0

updateDebugValues(0)

RunService.Heartbeat:Connect(function(deltaTime)
	elapsed += deltaTime
	frameCount += 1

	if elapsed < UPDATE_INTERVAL_SECONDS then
		return
	end

	local fps = frameCount / elapsed
	elapsed = 0
	frameCount = 0
	updateDebugValues(fps)
end)
