--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionControllerModule)

-- ROBLOX OBJECTS
local fireMunitionRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunition
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunition

-- FINALS
local log: Logger.SelfObject = Logger.new("RaycastBallisticHandlerClient")

function funcs.fireMunitionRaycast(ray: MunitionController.RayInfo)
	local config = ray.MunitionConfig
	if config.EnableBallistics then return end

	assert(ray.Origin)
	log:trace("Raycast-Firing munition {} with rayId {}", ray.MunitionConfig.MunitionName, ray.RayId)

	local initOrigin: Vector3 = ray.Body.InitOriginPos
	local initDir: Vector3 = ray.Body.InitDirection
	local result: RaycastResult? = workspace:Raycast(initOrigin, initDir * config.MaxDistance, ray.RaycastParams)

	local rayRequest: MunitionRayInfo.ClientRequest = {
		RayId = ray.RayId,
		MunitionName = ray.MunitionConfig.MunitionName,
		Origin = ray.Origin,
		Body = ray.Body
	}
	local rayHit: MunitionRayHitInfo.Common = {
		HitPos = result and result.Position or initOrigin + initDir * config.MaxDistance,
		Hit = result and result.Instance :: BasePart?
	}

	fireMunitionRemote:FireServer(rayRequest, rayHit)
    
    MunitionController.processFireMunition(ray)
    MunitionController.processRaySegment(ray, {
        OriginPos = initOrigin,
        DirectionVec = initDir,
        Length = config.MaxDistance
    })
    MunitionController.processRayEnd(ray, rayHit)
end

function funcs.handleReplicationRaycast(ray: MunitionRayInfo.ServerReplication, hit: MunitionRayHitInfo.Common)
	if ray.Player then
		log:trace("Handling replication raycast event from player {}", ray.Player.Name) 
	end

	local resolvedConfig: MunitionConfigUtil.DefaultType? = MunitionConfigUtil.getConfig(ray.MunitionName)
	assert(resolvedConfig)

	local transformedClientRay: MunitionController.RayInfo = {
        Player = ray.Player,
        Team = ray.Team,
		RayId = ray.RayId,
		MunitionConfig = resolvedConfig,
		Origin = ray.Origin,
		Body = ray.Body
	}

    MunitionController.processFireMunition(transformedClientRay)
    MunitionController.processRaySegment(transformedClientRay, {
        OriginPos = ray.Body.InitOriginPos,
        DirectionVec = ray.Body.InitDirection,
        Length = (hit.HitPos - ray.Body.InitOriginPos).Magnitude
    })
    MunitionController.processRayEnd(transformedClientRay, hit)
end

replicationRemote.OnClientEvent:Connect(funcs.handleReplicationRaycast)
MunitionController.PreFire:connect(funcs.fireMunitionRaycast)

return module
