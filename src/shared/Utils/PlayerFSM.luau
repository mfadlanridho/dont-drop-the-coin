--!nonstrict
--[[
    PlayerFSM.luau
    Manager instantiating OOP StateMachine per player with registered state definitions (Normal, Dashing, Ragdolled, SafeZone).
    Location: src/shared/Utils/PlayerFSM.luau (Syncs to ReplicatedStorage.Shared.Utils.PlayerFSM)
--]]

local Players = game:GetService("Players")

local Utils = script.Parent
local StateMachine = require(Utils:WaitForChild("StateMachine"))
local States = Utils:WaitForChild("States")

local NormalState = require(States:WaitForChild("NormalState"))
local DashingState = require(States:WaitForChild("DashingState"))
local RagdollState = require(States:WaitForChild("RagdollState"))
local SafeZoneState = require(States:WaitForChild("SafeZoneState"))

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

		-- Set initial state
		local char = player.Character
		local context: StateMachine.StateContext = {
			player = player,
			character = char,
			humanoid = char and char:FindFirstChildOfClass("Humanoid"),
			rootPart = char and char:FindFirstChild("HumanoidRootPart") :: BasePart,
		}
		machine:setState("Normal", context)
		PlayerMachines[player] = machine
	end
	return machine
end

-- Get Current Player State Name
function PlayerFSM.GetState(player: Player): string
	local machine = getOrCreateMachine(player)
	return machine:getCurrentStateName() or "Normal"
end

-- Set Player State with Lifecycle Validation
function PlayerFSM.SetState(player: Player, newStateName: string): boolean
	local machine = getOrCreateMachine(player)
	local char = player.Character
	local context: StateMachine.StateContext = {
		player = player,
		character = char,
		humanoid = char and char:FindFirstChildOfClass("Humanoid"),
		rootPart = char and char:FindFirstChild("HumanoidRootPart") :: BasePart,
	}
	return machine:setState(newStateName, context)
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
