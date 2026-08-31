--!strict
--[[
    Logger.luau
    Bridge forwarding to ReplicatedStorage.Packages.LoggerModule submodule.
    Location: src/shared/Utils/Logger.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local LoggerModule = require(Packages:WaitForChild("LoggerModule") :: ModuleScript)

return LoggerModule
