--!nonstrict
--[[
    PlayerFSM.luau
    Manager instantiating OOP StateMachine per player with registered state definitions (Normal, Dashing, Ragdolled, SafeZone).
    Includes network attribute replication (FSMState) to keep Server and Client states perfectly synced across the network.
    Location: src/shared/Utils/PlayerFSM.luau (Syncs to ReplicatedStorage.Shared.Utils.PlayerFSM)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Utils = script.Parent
local StateMachine = require(Utils:WaitForChild("StateMachine"))
local States = Utils:WaitForChild("States")

local NormalState = require(States:WaitForChild("NormalState"))
local DashingState = require(States:WaitForChild("DashingState"))
local RagdollState = require(States:WaitForChild("RagdollState"))
local SafeZoneState = require(States:WaitForChild("SafeZoneState"))

local ATTRIBUTE_NAME = "FSMState"
local PlayerMachines: { [Player]: StateMachine.StateMachineInstance } = {}
local PlayerFSM = {}

-- Create & Register StateMachine for Player
local function getOrCreateMachine(player: Player): StateMachine.StateMachineInstance
	local machine = PlayerMachines[player]
	if not machine then
		machine = StateMachine.new(function(oldState, newState)
			-- State change callback logger
		end)

		-- Register All State Definitions
		machine:registerState(NormalState)
		machine:registerState(DashingState)
		machine:registerState(RagdollState)
		machine:registerState(SafeZoneState)

		-- Initial State Context
		local char = player.Character
		local context: StateMachine.StateContext = {
			player = player,
			character = char,
			humanoid = char and char:FindFirstChildOfClass("Humanoid"),
			rootPart = char and char:FindFirstChild("HumanoidRootPart") :: BasePart,
		}

		local initialState = player:GetAttribute(ATTRIBUTE_NAME) or "Normal"
		machine:setState(initialState, context)
		PlayerMachines[player] = machine

		-- Server: Initialize network attribute
		if RunService:IsServer() and not player:GetAttribute(ATTRIBUTE_NAME) then
			player:SetAttribute(ATTRIBUTE_NAME, initialState)
		end

		-- Client: Listen to server attribute updates to sync local FSM
		if RunService:IsClient() then
			player:GetAttributeChangedSignal(ATTRIBUTE_NAME):Connect(function()
				local serverState = player:GetAttribute(ATTRIBUTE_NAME)
				if serverState and machine:getCurrentStateName() ~= serverState then
					local updatedChar = player.Character
					local updatedContext: StateMachine.StateContext = {
						player = player,
						character = updatedChar,
						humanoid = updatedChar and updatedChar:FindFirstChildOfClass("Humanoid"),
						rootPart = updatedChar and updatedChar:FindFirstChild("HumanoidRootPart") :: BasePart,
					}
					machine:setState(serverState, updatedContext)
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
	local machine = getOrCreateMachine(player)
	local char = player.Character
	local context: StateMachine.StateContext = {
		player = player,
		character = char,
		humanoid = char and char:FindFirstChildOfClass("Humanoid"),
		rootPart = char and char:FindFirstChild("HumanoidRootPart") :: BasePart,
	}

	local success = machine:setState(newStateName, context)
	if success then
		-- Replicate state change from Server to Client via Attribute
		if RunService:IsServer() then
			player:SetAttribute(ATTRIBUTE_NAME, newStateName)
		end
	end

	return success
end

-- Check if Player Can Cast Dash Bump
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
end)

return PlayerFSM
