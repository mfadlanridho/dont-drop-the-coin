--!nonstrict
--[[
    Remotes.luau
    Central remote events registry module.
    Location: src/shared/Remotes.luau (Syncs to ReplicatedStorage.Shared.Remotes)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
	if RunService:IsServer() then
		RemotesFolder = Instance.new("Folder")
		RemotesFolder.Name = "Remotes"
		RemotesFolder.Parent = ReplicatedStorage
	else
		RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	end
end

local Remotes = {}

local REMOTE_NAMES = {
	"PickupCoin",
	"UpdateStack",
	"DashBump",
	"DashBumpHit",
	"SimulateDashBump",
	"SpawnTestDummy",
	"BankCoins",
	"TriggerRagdoll",
	"UpdateHUD",
	"PlayVFX",
	"PlaySound",
	"SendNotification",
}

-- Initialize Remote Events
for _, remoteName in ipairs(REMOTE_NAMES) do
	local event = RemotesFolder:FindFirstChild(remoteName)
	if not event and RunService:IsServer() then
		event = Instance.new("RemoteEvent")
		event.Name = remoteName
		event.Parent = RemotesFolder
	end
	if event then
		Remotes[remoteName] = event
	end
end

function Remotes.Get(remoteName: string): RemoteEvent
	local event = RemotesFolder:WaitForChild(remoteName, 5) :: RemoteEvent
	if not event then
		error(string.format("[Remotes] Could not find RemoteEvent: %s", remoteName))
	end
	return event
end

return Remotes
