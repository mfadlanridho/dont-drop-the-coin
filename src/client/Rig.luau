--!nonstrict
--[[
    Rig.luau
    Observes local player character, humanoid, and rootPart for animation runtime.
    Location: src/client/Rig.luau (Syncs to StarterPlayerScripts.Client.Rig)
--]]

local Players = game:GetService("Players")

local Rig = {}

local localPlayer = Players.LocalPlayer
local started = false
local playerConnections = {}
local listeners = {}
local state = {
	character = nil,
	humanoid = nil,
	rootPart = nil,
}

local function disconnectConnections(connections)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function bindCharacter(character: Model?)
	state.character = character
	state.humanoid = nil
	state.rootPart = nil

	if character ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")

		if humanoid ~= nil then
			state.humanoid = humanoid
		end

		if rootPart ~= nil and rootPart:IsA("BasePart") then
			state.rootPart = rootPart
		end
	end

	for _, listener in ipairs(listeners) do
		listener(state)
	end
end

function Rig.start()
	if started then return end
	started = true

	if localPlayer.Character ~= nil then
		bindCharacter(localPlayer.Character)
	end

	table.insert(playerConnections, localPlayer.CharacterAdded:Connect(bindCharacter))
	table.insert(playerConnections, localPlayer.CharacterRemoving:Connect(function(character)
		if character == state.character then
			bindCharacter(nil)
		end
	end))
end

function Rig.stop()
	if not started then return end
	started = false
	disconnectConnections(playerConnections)
	bindCharacter(nil)
end

function Rig.getState()
	return state
end

function Rig.observe(listener: (typeof(state)) -> ()): () -> ()
	table.insert(listeners, listener)
	listener(state)

	return function()
		local index = table.find(listeners, listener)
		if index ~= nil then
			table.remove(listeners, index)
		end
	end
end

return Rig
