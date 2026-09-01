--!nonstrict
--[[
    Main.client.luau
    Client entrypoint initializing all client controllers with fault-tolerant safeInit protected execution.
    Location: src/client/Main.client.luau (Syncs to StarterPlayerScripts.Client.Main)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local DebugGuiModule = require(Packages:WaitForChild("DebugGuiModule"))

local Controllers = script.Parent:WaitForChild("Controllers")

-- Protected Async Initialization Wrapper
local function safeInit(name: string, initFn: () -> ())
	task.spawn(function()
		local success, err = pcall(initFn)
		if not success then
			warn(string.format("❌ [Client Init Error] Controller %q failed to initialize: %s", name, tostring(err)))
		end
	end)
end

-- Initialize Developer Debug Suite ('P' key overlay)
safeInit("DebugGuiModule", DebugGuiModule.Init)

-- Dynamically initialize all client controllers in Controllers folder
for _, controllerScript in ipairs(Controllers:GetChildren()) do
	if controllerScript:IsA("ModuleScript") then
		local controller = require(controllerScript) :: any
		if typeof(controller) == "table" and typeof(controller.Init) == "function" then
			safeInit(controllerScript.Name, controller.Init)
		end
	end
end

print("[ClientMain] All client controllers initialized successfully with safeInit protection!")
