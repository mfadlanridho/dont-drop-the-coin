--!nonstrict
--[[
    AnimationControllerInstance.luau
    Singleton instance of AnimationControllerV2 for client-wide animation playback.
    Location: src/client/Animation/AnimationControllerInstance.luau
--]]

local AnimationControllerV2 = require(script.Parent:WaitForChild("AnimationControllerV2"))
local controller = AnimationControllerV2.new()

return controller
