--!nonstrict
--[[
    CombatServer.luau
    Handles server-side Dash Bump cooldowns, forward raycast hitboxes, stack-scaled knockback impulse, and ragdoll explosion triggers.
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

	-- Forward Dash Velocity Burst calculated from DASH_DISTANCE / DASH_DURATION
	local dashSpeed = Config.DASH_DISTANCE / math.max(0.05, Config.DASH_DURATION)
	hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * dashSpeed + Vector3.new(0, 10, 0)

	-- OverlapParams Hitbox Search in front of Attacker
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }

	local hitParts = Workspace:GetPartBoundsInBox(
		hrp.CFrame * CFrame.new(0, 0, -4),
		Vector3.new(6, 6, 8),
		overlapParams
	)

	local processedVictims = {}

	for _, part in ipairs(hitParts) do
		local victimChar = part.Parent
		local victim = Players:GetPlayerFromCharacter(victimChar)

		if victim and victim ~= player and not processedVictims[victim] then
			processedVictims[victim] = true

			if PlayerFSM.CanBeBumped(victim) then
				local victimHrp = victimChar:FindFirstChild("HumanoidRootPart") :: Part
				if victimHrp then
					-- Calculate Stack-Scaled Knockback Force
					local victimStack = StackServer.GetStackCount(victim)
					local knockbackForce = Config.BUMP_BASE_IMPULSE + (victimStack * Config.BUMP_STACK_IMPULSE_MULTIPLIER)
					local launchVector = (victimHrp.Position - hrp.Position).Unit * knockbackForce + Vector3.new(0, 30, 0)

					-- Apply Knockback Impulse
					victimHrp:ApplyImpulse(launchVector)

					-- Trigger Ragdoll State & Explode Head Stack
					RagdollModule.TriggerRagdoll(victim, Config.RAGDOLL_DURATION)
					LootExplosion.ScatterCoins(victim)

					print(string.format("[CombatServer] %s BUMPED %s! (Launch Force: %.1f)", player.Name, victim.Name, knockbackForce))
				end
			end
		end
	end

	-- Reset FSM State after dash duration
	task.delay(0.3, function()
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

	Players.PlayerRemoving:Connect(function(player)
		LastBumpTime[player.UserId] = nil
	end)
end

return CombatServer
