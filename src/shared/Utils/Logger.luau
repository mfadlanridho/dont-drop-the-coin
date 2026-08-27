--!strict
--[[
    Logger.luau
    Centralized, category-driven debug logging system for Client & Server.
    Location: src/shared/Utils/Logger.luau (Syncs to ReplicatedStorage.Shared.Utils.Logger)

    How it works:
    - Checks RunService:IsStudio() to enable/disable logs based on environment.
    - Maintains a Categories dictionary specifying which systems should output logs.
    - Logger.log(category, ...) checks if the category is enabled and outputs [category] prefix.
    - Logger.create(category) returns a scoped debugLog function bound to that category.
--]]

local RunService = game:GetService("RunService")

local IS_STUDIO: boolean = RunService:IsStudio()

export type CategoryMap = { [string]: boolean }

local Categories: CategoryMap = {
	Combat = IS_STUDIO and true,
	Input = IS_STUDIO and true,
	Ragdoll = IS_STUDIO and true,
	DataStore = IS_STUDIO and true,
	CoinSpawner = IS_STUDIO and true,
	FSM = IS_STUDIO and true,
	DebugGui = IS_STUDIO and true,
	Shop = IS_STUDIO and true,
	LootExplosion = IS_STUDIO and true,
	Audio = IS_STUDIO and true,
	Bank = IS_STUDIO and true,
}

local Logger = {}
Logger.Categories = Categories

--- Central logging function. Prints `[category]` followed by arguments if category toggle is true.
function Logger.log(category: string, ...: any)
	if Logger.Categories[category] == true then
		print(string.format("[%s]", category), ...)
	end
end

--- Factory helper to create a category-scoped logging function `debugLog(...)`.
function Logger.create(category: string): (...any) -> ()
	return function(...: any)
		Logger.log(category, ...)
	end
end

return Logger
