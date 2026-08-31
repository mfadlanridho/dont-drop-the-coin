--!nonstrict
--[[
    PlayerFSM.luau
    Manager instantiating OOP StateMachine per player with registered state definitions (Normal, Dashing, Ragdolled, SafeZone).
    Locomotion physics & animation hooks run strictly on the CLIENT with persistent context tables.
    Location: src/shared/Utils/PlayerFSM.luau (Syncs to ReplicatedStorage.Shared.Utils.PlayerFSM)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Utils = script.Parent
local StateMachine = require(Packages:WaitForChild("StateMachineModule"))
local States = Utils:WaitForChild("States")
local Logger = require(Packages:WaitForChild("LoggerModule"))

local log = Logger.create("FSM")

local NormalState = require(States:WaitForChild("NormalState"))
local DashingState = require(States:WaitForChild("DashingState"))
local RagdollState = require(States:WaitForChild("RagdollState"))
local SafeZoneState = require(States:WaitForChild("SafeZoneState"))

local ATTRIBUTE_NAME = "FSMState"
local PlayerMachines: { [Player]: StateMachine.StateMachineInstance } = {}
local PlayerContexts: { [Player]: StateMachine.StateContext } = {}

local PlayerFSM = {}

local function getOrCreateContext(player: Player): StateMachine.StateContext
	local context = PlayerContexts[player]
	local char = player.Character
	if not context or context.character ~= char then
		context = {
			player = player,
			character = char,
			humanoid = char and char:FindFirstChildOfClass("Humanoid"),
			rootPart = char and char:FindFirstChild("HumanoidRootPart") :: BasePart,
		}
		PlayerContexts[player] = context
	else
		context.character = char
		context.humanoid = char and char:FindFirstChildOfClass("Humanoid")
		context.rootPart = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
	end
	return context
end

-- Create & Register StateMachine for Player
local function getOrCreateMachine(player: Player): StateMachine.StateMachineInstance
	local machine = PlayerMachines[player]
	if not machine then
		machine = StateMachine.new(function(oldState, newState)
			log(string.format("[%s] %s -> %s (%s)", player.Name, tostring(oldState), tostring(newState), RunService:IsServer() and "SERVER" or "CLIENT"))
		end)

		-- Register All State Definitions
		machine:registerState(NormalState)
		machine:registerState(DashingState)
		machine:registerState(RagdollState)
		machine:registerState(SafeZoneState)

		local initialState = player:GetAttribute(ATTRIBUTE_NAME) or "Normal"
		local context = getOrCreateContext(player)

		-- Execute state hooks ONLY on Client
		if RunService:IsClient() then
			machine:setState(initialState, context)
		end

		PlayerMachines[player] = machine

		-- Server: Initialize network attribute
		if RunService:IsServer() and not player:GetAttribute(ATTRIBUTE_NAME) then
			player:SetAttribute(ATTRIBUTE_NAME, initialState)
		end

		-- Client: Listen to server attribute updates to sync local FSM
		if RunService:IsClient() then
			player:GetAttributeChangedSignal(ATTRIBUTE_NAME):Connect(function()
				local serverState = player:GetAttribute(ATTRIBUTE_NAME)
				log(string.format("Attribute signal: Server set FSMState to %q", tostring(serverState)))
				if serverState and machine:getCurrentStateName() ~= serverState then
					local updatedContext = getOrCreateContext(player)
					local setSuccess, errReason = machine:setState(serverState, updatedContext)
					log(string.format("Client setState result: %s (Reason: %s)", tostring(setSuccess), tostring(errReason)))
				end
			end)
		end
	end
	return machine
end

-- Get Current Player State Name
function PlayerFSM.GetState(player: Player): string
	local attrState = player:GetAttribute(ATTRIBUTE_NAME)
	if attrState then
		return attrState
	end

	local machine = getOrCreateMachine(player)
	return machine:getCurrentStateName() or "Normal"
end

-- Set Player State with Lifecycle Validation & Network Replication
function PlayerFSM.SetState(player: Player, newStateName: string): boolean
	log(string.format("SetState TargetState: %s | Env: %s", newStateName, RunService:IsServer() and "SERVER" or "CLIENT"))

	-- Server: Only update replicated network attribute
	if RunService:IsServer() then
		player:SetAttribute(ATTRIBUTE_NAME, newStateName)
		log(string.format("Server set attribute %s = %s", ATTRIBUTE_NAME, newStateName))
		return true
	end

	-- Client: Execute local state machine lifecycle hooks (enter, exit, update)
	local machine = getOrCreateMachine(player)
	local context = getOrCreateContext(player)

	return machine:setState(newStateName, context)
end

-- Check if Player Can Dash Bump
function PlayerFSM.CanDash(player: Player): boolean
	local state = PlayerFSM.GetState(player)
	return state == "Normal"
end

-- Check if Player Can Be Bumped / Ragdolled
function PlayerFSM.CanBeBumped(player: Player): boolean
	local state = PlayerFSM.GetState(player)
	return state ~= "SafeZone" and state ~= "Ragdolled"
end

-- Clean up on leave
Players.PlayerRemoving:Connect(function(player)
	PlayerMachines[player] = nil
	PlayerContexts[player] = nil
end)

return PlayerFSM
