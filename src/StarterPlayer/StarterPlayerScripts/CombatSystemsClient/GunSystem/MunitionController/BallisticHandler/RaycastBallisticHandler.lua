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
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)

-- ROBLOX OBJECTS
local fireMunitionRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunition
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunition

-- FINALS
local log: Logger.SelfObject = Logger.new("RaycastBallisticHandler")

function funcs.fireMunitionRaycast(rayInfo: MunitionController.RayInfo)
	log:debug("Raycast-Firing munition {} with rayId {}", rayInfo.MunitionConfig.MunitionName, rayInfo.RayId)

	local config = rayInfo.MunitionConfig
	local initOrigin: Vector3 = rayInfo.InitOriginPos
	local initDir: Vector3 = rayInfo.InitDirection

	local result: RaycastResult? = workspace:Raycast(initOrigin, initDir * config.MaxDistance, rayInfo.RaycastParams)
	local hitPos: Vector3 = result and result.Position or initOrigin + initDir * config.MaxDistance
	local hit = result and result.Instance :: BasePart?

	local rayClientRequest: MunitionRayInfo.ClientRequest = {
		RayId = rayInfo.RayId,
		MunitionName = rayInfo.MunitionConfig.MunitionName,
		Origin = rayInfo.Origin,
		InitOriginPos = rayInfo.InitOriginPos,
		InitDirection = rayInfo.InitDirection
	}
	local rayHitClientRequest: MunitionRayHitInfo.ClientRequest = {
		RayInfo = rayClientRequest,
		HitPos = hitPos,
		Hit = hit
	}

	fireMunitionRemote:FireServer(rayHitClientRequest)

	local rayHitInfo: MunitionController.RayHitInfo = {
		RayInfo = rayInfo,
		HitPos = hitPos,
		Hit = hit,
	}
    
    MunitionController.processFireMunition(rayInfo)
    MunitionController.processRaySegment({
        RayInfo = rayInfo,
        OriginPos = initOrigin,
        DirectionVec = initDir,
        Length = config.MaxDistance
    })
    MunitionController.processRayEnd(rayHitInfo)
end

function funcs.handleReplicationRaycast(rayHitInfo: MunitionRayHitInfo.ServerReplication)
	local rayInfo: MunitionRayInfo.ServerReplication = rayHitInfo.RayInfo
	if rayInfo.Player then log:debug("Handling replication raycast event from player {}", rayInfo.Player.Name) end

	local resolvedConfig: MunitionConfigUtil.DefaultType? = MunitionConfigUtil.getConfig(rayInfo.MunitionName)
	assert(resolvedConfig)

	local resolvedRayInfo: MunitionController.RayInfo = {
        Player = rayInfo.Player,
        Team = rayInfo.Team,
		RayId = rayInfo.RayId,
		MunitionConfig = resolvedConfig,
		Origin = rayInfo.Origin,
		InitOriginPos = rayInfo.InitOriginPos,
		InitDirection = rayInfo.InitDirection
	}
    local resolvedRayHitInfo: MunitionController.RayHitInfo = {
        RayInfo = resolvedRayInfo,
        HitPos = rayHitInfo.HitPos,
        Hit = rayHitInfo.Hit
    }

    MunitionController.processFireMunition(resolvedRayInfo)
    MunitionController.processRaySegment({
        RayInfo = resolvedRayInfo,
        OriginPos = rayInfo.InitOriginPos,
        DirectionVec = rayInfo.InitDirection,
        Length = (rayHitInfo.HitPos - rayInfo.InitOriginPos).Magnitude
    })
    MunitionController.processRayEnd(resolvedRayHitInfo)
end

replicationRemote.OnClientEvent:Connect(funcs.handleReplicationRaycast)
MunitionController.PreFire:connect(funcs.fireMunitionRaycast)

return module
