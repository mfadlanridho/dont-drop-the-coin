--!nonstrict
--[[
    Main.client.luau
    Client entrypoint initializing all client controllers.
    Location: src/client/Main.client.luau (Syncs to StarterPlayerScripts.Client.Main)
--]]

local Controllers = script.Parent:WaitForChild("Controllers")
local StackVisualizer = require(Controllers:WaitForChild("StackVisualizer"))
local InputController = require(Controllers:WaitForChild("InputController"))

StackVisualizer.Init()
InputController.Init()

print("[ClientMain] All client controllers initialized successfully!")
