--!nonstrict
--[[
    CombatServer.luau
    Handles server-side Dash Bump cooldowns, Workspace:Spherecast 3D swept hitboxes, stack-scaled knockback impulse, and ragdoll explosion triggers.
    Location: src/server/Services/CombatServer.luau (Syncs to ServerScriptService.Server.Services.CombatServer)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))

local Services = script.Parent
local StackServer = require(Services:WaitForChild("StackServer"))
local RagdollModule = require(Services:WaitForChild("RagdollModule"))
local LootExplosion = require(Services:WaitForChild("LootExplosion"))

local LastBumpTime: { [number]: number } = {}
local CombatServer = {}

-- Execute Full Combat Bump API on a Victim
function CombatServer.BumpVictim(attackerPlayer: Player?, victim: Player)
	if not PlayerFSM.CanBeBumped(victim) then return end
	local victimChar = victim.Character
	local victimHrp = victimChar and victimChar:FindFirstChild("HumanoidRootPart") :: Part
	if not victimHrp then return end

	local attackerChar = attackerPlayer and attackerPlayer.Character
	local attackerHrp = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart") :: Part
	local launchDir = if attackerHrp then (victimHrp.Position - attackerHrp.Position).Unit else -victimHrp.CFrame.LookVector

	-- Calculate Stack-Scaled Knockback Force
	local victimStack = StackServer.GetStackCount(victim)
	local knockbackForce = Config.BUMP_BASE_IMPULSE + (victimStack * Config.BUMP_STACK_IMPULSE_MULTIPLIER)
	local launchVector = launchDir * knockbackForce + Vector3.new(0, 35, 0)

	-- Trigger Physics Ragdoll State & Explode Head Stack
	RagdollModule.TriggerRagdoll(victim, Config.RAGDOLL_DURATION)
	LootExplosion.ScatterCoins(victim)

	-- Fire client ragdoll & knockback launch event to victim
	local ragdollRemote = Remotes.Get("TriggerRagdoll")
	if ragdollRemote then
		ragdollRemote:FireClient(victim, Config.RAGDOLL_DURATION, launchVector)
	end

	-- Fire client hit visualizer event
	local hitEvent = Remotes.Get("DashBumpHit")
	if hitEvent then
		hitEvent:FireAllClients(attackerPlayer or victim, victim.Name, victimHrp.Position, knockbackForce)
	end

	print(string.format("[CombatServer] %s BUMPED %s! (Launch Force: %.1f, Stack: %d)", attackerPlayer and attackerPlayer.Name or "System", victim.Name, knockbackForce, victimStack))
end

-- Handle Client Dash Bump Request
local function handleDashBump(player: Player)
	local userId = player.UserId
	local now = os.clock()

	-- Server Cooldown Guard (5.0 Seconds)
	if LastBumpTime[userId] and (now - LastBumpTime[userId]) < Config.BUMP_COOLDOWN then
		warn(string.format("[CombatServer] %s attempted Dash Bump before cooldown expired!", player.Name))
		return
	end

	-- Check FSM State
	if not PlayerFSM.CanDash(player) then
		return
	end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then return end

	LastBumpTime[userId] = now
	PlayerFSM.SetState(player, "Dashing")

	-- 1. Primary 3D Spherecast Sweep along 15-stud forward dash path
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = true

	local sphereRadius = 4.5
	local dashDirection = hrp.CFrame.LookVector * Config.DASH_DISTANCE

	local processedVictims = {}

	local spherecastResult = Workspace:Spherecast(
		hrp.Position,
		sphereRadius,
		dashDirection,
		raycastParams
	)

	if spherecastResult and spherecastResult.Instance then
		local victimChar = spherecastResult.Instance.Parent
		if victimChar and victimChar:FindFirstChildOfClass("Humanoid") == nil and victimChar.Parent then
			victimChar = victimChar.Parent
		end

		local victim = Players:GetPlayerFromCharacter(victimChar)
		if victim and victim ~= player then
			processedVictims[victim] = true
		end
	end

	-- 2. Secondary Overlap Volume check along dash corridor to guarantee multi-victim detection
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }

	local corridorCenter = hrp.CFrame * CFrame.new(0, 0, -Config.DASH_DISTANCE * 0.5)
	local corridorSize = Vector3.new(sphereRadius * 2, 7, Config.DASH_DISTANCE + 4)
	local corridorParts = Workspace:GetPartBoundsInBox(corridorCenter, corridorSize, overlapParams)

	for _, part in ipairs(corridorParts) do
		local victimChar = part.Parent
		local victim = Players:GetPlayerFromCharacter(victimChar)
		if victim and victim ~= player then
			processedVictims[victim] = true
		end
	end

	-- Process all detected victims using full Combat API
	for victim, _ in pairs(processedVictims) do
		CombatServer.BumpVictim(player, victim)
	end

	-- Reset FSM State after dash duration
	task.delay(Config.DASH_DURATION, function()
		if PlayerFSM.GetState(player) == "Dashing" then
			PlayerFSM.SetState(player, "Normal")
		end
	end)
end

-- Initialize Listeners
function CombatServer.Init()
	local bumpEvent = Remotes.Get("DashBump")
	if bumpEvent then
		bumpEvent.OnServerEvent:Connect(handleDashBump)
	end

	local simBumpEvent = Remotes.Get("SimulateDashBump")
	if simBumpEvent then
		simBumpEvent.OnServerEvent:Connect(function(player)
			CombatServer.BumpVictim(nil, player)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		LastBumpTime[player.UserId] = nil
	end)
end

return CombatServer
