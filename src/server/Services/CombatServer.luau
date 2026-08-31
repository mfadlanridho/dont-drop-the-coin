--!nonstrict
--[[
    CombatServer.luau
    Handles server-side Dash Bump cooldowns, Workspace:Spherecast 3D swept hitboxes, stack-scaled knockback impulse, and ragdoll explosion triggers for players & dummies.
    Location: src/server/Services/CombatServer.luau (Syncs to ServerScriptService.Server.Services.CombatServer)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local PlayerFSM = require(Shared:WaitForChild("Utils"):WaitForChild("PlayerFSM"))
local Packages = ReplicatedStorage:WaitForChild("Packages")
local RagdollModule = require(Packages:WaitForChild("RagdollModule") :: ModuleScript)
local Logger = require(Packages:WaitForChild("LoggerModule"))

local log = Logger.create("Combat")

local Services = script.Parent
local LootExplosion = require(Services:WaitForChild("LootExplosion"))
local HitboxService = require(Services:WaitForChild("HitboxService"))

local LastBumpTime: { [number]: number } = {}
local CombatServer = {}

-- Execute Full Combat Bump API on a Victim (Player or Dummy Model)
function CombatServer.BumpVictimModel(attackerPlayer: Player?, victimModel: Model)
	local victimHrp = victimModel:FindFirstChild("HumanoidRootPart") :: Part
	if not victimHrp then return end

	local attackerChar = attackerPlayer and attackerPlayer.Character
	local attackerHrp = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart") :: Part
	local launchDir = if attackerHrp then (victimHrp.Position - attackerHrp.Position).Unit else -victimHrp.CFrame.LookVector

	local knockbackForce = Config.BUMP_BASE_IMPULSE
	local launchVector = launchDir * knockbackForce + Vector3.new(0, 35, 0)

	-- Check if victim is a Player or an NPC Dummy Model
	local victimPlayer = Players:GetPlayerFromCharacter(victimModel)

	if victimPlayer then
		if not PlayerFSM.CanBeBumped(victimPlayer) then return end
		PlayerFSM.SetState(victimPlayer, "Ragdolled")
		RagdollModule.SetPlatformStand(victimModel, true, true)
		LootExplosion.ScatterCoins(victimPlayer)

		local ragdollRemote = Remotes.Get("TriggerRagdoll")
		if ragdollRemote then
			ragdollRemote:FireClient(victimPlayer, Config.RAGDOLL_DURATION, launchVector)
		end

		task.delay(Config.RAGDOLL_DURATION or 2.5, function()
			if victimModel and victimModel.Parent then
				RagdollModule.SetPlatformStand(victimModel, false, false)
			end
			pcall(function()
				PlayerFSM.SetState(victimPlayer, "Normal")
			end)
		end)
	else
		-- Direct physics launch for NPC Test Target Dummy
		victimHrp.AssemblyLinearVelocity = launchVector
		local torso = victimModel:FindFirstChild("UpperTorso") :: Part
		if torso then
			torso.AssemblyLinearVelocity = launchVector + Vector3.new(math.random(-10, 10), 10, math.random(-10, 10))
		end
	end

	-- Fire client hit visualizer & 3D sound event to all clients
	local hitEvent = Remotes.Get("DashBumpHit")
	if hitEvent then
		hitEvent:FireAllClients(attackerPlayer or victimPlayer, victimModel.Name, victimHrp.Position, knockbackForce)
	end

	local soundRemote = Remotes.Get("PlaySound")
	if soundRemote then
		soundRemote:FireAllClients("RagdollHit", victimHrp)
	end

	log(string.format("%s BUMPED %s! (Launch Force: %.1f)", attackerPlayer and attackerPlayer.Name or "System", victimModel.Name, knockbackForce))
end

-- Execute Full Combat Bump API on a Victim Player
function CombatServer.BumpVictim(attackerPlayer: Player?, victim: Player)
	if victim and victim.Character then
		CombatServer.BumpVictimModel(attackerPlayer, victim.Character)
	end
end

-- Handle Client Dash Bump Request
local function handleDashBump(player: Player, clientTargetVictim: Player?)
	log(string.format("handleDashBump received from player %s", player.Name))
	local userId = player.UserId
	local now = os.clock()

	-- Server Cooldown Guard (5.0 Seconds)
	if LastBumpTime[userId] and (now - LastBumpTime[userId]) < Config.BUMP_COOLDOWN then
		warn(string.format("[CombatServer] %s attempted Dash Bump before cooldown expired! (Remaining: %.2fs)", player.Name, Config.BUMP_COOLDOWN - (now - LastBumpTime[userId])))
		return
	end

	-- Check FSM State
	local canDash = PlayerFSM.CanDash(player)
	log(string.format("Player %s CanDash check: %s (State: %s)", player.Name, tostring(canDash), PlayerFSM.GetState(player)))
	if not canDash then
		return
	end

	local character = player.Character
	if not character then
		warn(string.format("[CombatServer] %s has no character!", player.Name))
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: Part
	if not hrp then
		warn(string.format("[CombatServer] %s character has no HumanoidRootPart!", player.Name))
		return
	end

	LastBumpTime[userId] = now
	PlayerFSM.SetState(player, "Dashing")

	-- Fire Dash Bump 3D audio to all clients
	local soundRemote = Remotes.Get("PlaySound")
	if soundRemote then
		soundRemote:FireAllClients("DashBump", hrp)
	end

	-- If client reported a direct target hit validation, verify distance and bump immediately
	if clientTargetVictim and clientTargetVictim:IsA("Player") and clientTargetVictim ~= player then
		local victimChar = clientTargetVictim.Character
		local victimHrp = victimChar and victimChar:FindFirstChild("HumanoidRootPart") :: Part
		if victimHrp and (victimHrp.Position - hrp.Position).Magnitude <= (Config.DASH_DISTANCE + 6) then
			CombatServer.BumpVictim(player, clientTargetVictim)
		end
	end

	-- Continuous 0.3s Heartbeat Hitbox Loop (runs every frame as the character lunges forward)
	local startTime = os.clock()
	local duration = Config.DASH_DURATION
	local sphereRadius = 4.5
	local processedVictims = {}

	local dashConnection: RBXScriptConnection?
	dashConnection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration or not character or not character.Parent or not hrp or not hrp.Parent then
			if dashConnection then
				dashConnection:Disconnect()
				dashConnection = nil
			end
			if PlayerFSM.GetState(player) == "Dashing" then
				PlayerFSM.SetState(player, "Normal")
			end
			return
		end

		local targetHitboxes = HitboxService.GetTargetHitboxes(player)
		if #targetHitboxes == 0 then return end

		-- 1. Spherecast along current movement vector
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = targetHitboxes
		raycastParams.IgnoreWater = true

		local spherecastResult = Workspace:Spherecast(
			hrp.Position,
			sphereRadius,
			hrp.CFrame.LookVector * 4.0,
			raycastParams
		)

		if spherecastResult and spherecastResult.Instance then
			local vChar = spherecastResult.Instance.Parent
			if vChar and vChar:FindFirstChildOfClass("Humanoid") == nil and vChar.Parent then
				vChar = vChar.Parent
			end
			if vChar and vChar:IsA("Model") and not processedVictims[vChar] then
				processedVictims[vChar] = true
				CombatServer.BumpVictimModel(player, vChar)
			end
		end

		-- 2. Box Overlap check centered at current position
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.FilterDescendantsInstances = targetHitboxes

		local currentBoxCenter = hrp.CFrame * CFrame.new(0, 0, -2)
		local currentBoxSize = Vector3.new(sphereRadius * 2, 7, 6)
		local corridorParts = Workspace:GetPartBoundsInBox(currentBoxCenter, currentBoxSize, overlapParams)

		for _, part in ipairs(corridorParts) do
			local vChar = part.Parent
			if vChar and vChar:FindFirstChildOfClass("Humanoid") == nil and vChar.Parent then
				vChar = vChar.Parent
			end
			if vChar and vChar:IsA("Model") and not processedVictims[vChar] then
				processedVictims[vChar] = true
				CombatServer.BumpVictimModel(player, vChar)
			end
		end
	end)
end

-- Initialize Listeners
function CombatServer.Init()
	local bumpEvent = Remotes.Get("DashBump")
	if bumpEvent then
		bumpEvent.OnServerEvent:Connect(handleDashBump)
		log("DashBump remote event listener registered successfully.")
	end

	Players.PlayerRemoving:Connect(function(player)
		LastBumpTime[player.UserId] = nil
	end)
end

return CombatServer
