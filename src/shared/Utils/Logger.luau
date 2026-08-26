local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()
local Logger = {}

-- Category toggles for debug logging:
-- • Use 'IS_STUDIO and true'  -> Logs ONLY in Studio (disabled in live games)
-- • Use 'true'                -> Logs in BOTH Studio and live games
-- • Use 'false'               -> Disabled everywhere
Logger.Categories = {
	Combat = IS_STUDIO and true,
	Input = IS_STUDIO and true,
	Ragdoll = IS_STUDIO and true,
	DataStore = IS_STUDIO and true,
	CoinSpawner = IS_STUDIO and true,
	FSM = IS_STUDIO and true,
	DebugGui = IS_STUDIO and true,
	Shop = IS_STUDIO and true,
	LootExplosion = IS_STUDIO and true,
}

-- Central logging function
function Logger.log(category: string, ...)
	if Logger.Categories[category] == true then
		print(string.format("[%s]", category), ...)
	end
end

-- Helper to create a category-scoped logger function
function Logger.create(category: string)
	return function(...)
		Logger.log(category, ...)
	end
end

return Logger
