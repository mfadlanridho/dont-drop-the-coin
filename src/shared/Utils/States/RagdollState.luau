--!nonstrict
--[[
    RagdollState.luau
    State definition for physics ragdoll & loot explosion state (2.5s duration).
    Location: src/shared/Utils/States/RagdollState.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local RagdollModule = require(Packages:WaitForChild("RagdollModule") :: ModuleScript)

return RagdollModule.State
