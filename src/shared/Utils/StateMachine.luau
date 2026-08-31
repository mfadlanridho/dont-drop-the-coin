--!strict
--[[
    StateMachine.luau
    Bridge forwarding to ReplicatedStorage.Packages.StateMachineModule submodule.
    Location: src/shared/Utils/StateMachine.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local StateMachineModule = require(Packages:WaitForChild("StateMachineModule") :: ModuleScript)

return StateMachineModule
