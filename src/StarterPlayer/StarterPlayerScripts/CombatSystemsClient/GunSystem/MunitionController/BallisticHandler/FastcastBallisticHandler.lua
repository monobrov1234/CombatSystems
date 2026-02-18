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
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local FastCastRedux = require(ReplicatedStorage.CombatSystemsShared.Libs.FastCastRedux)
local FastCastReduxTypes = require(ReplicatedStorage.CombatSystemsShared.Libs.FastCastRedux.TypeDefinitions)
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer :: Player

local fireMunitionBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunitionBallistic
local verifyHitBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.VerifyHitBallistic
local replicationBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunitionBallistic

-- FINALS
local log: Logger.SelfObject = Logger.new("FastcastBallisticHandler")
local caster = FastCastRedux.new()

function funcs.fireMunitionBallistic(rayInfo: MunitionController.RayInfo)
	log:debug("Fastcast-Firing munition {} with rayId {}", rayInfo.MunitionConfig.MunitionName, rayInfo.RayId)

	local config = rayInfo.MunitionConfig
	local initOrigin: Vector3 = rayInfo.InitOriginPos
	local initDir: Vector3 = rayInfo.InitDirection

	local castBehavior = funcs.newBehavior(rayInfo)
	local projectile = (caster :: any):Fire(initOrigin, initDir, initDir * config.BallisticConfig.Speed, castBehavior) :: FastCastReduxTypes.ActiveCast
	projectile.UserData = { RayInfo = rayInfo }

	local rayClientRequest: MunitionRayInfo.ClientRequest = {
		RayId = rayInfo.RayId,
		MunitionName = rayInfo.MunitionConfig.MunitionName,
		Origin = rayInfo.Origin,
		InitOriginPos = rayInfo.InitOriginPos,
		InitDirection = rayInfo.InitDirection
	}

	fireMunitionBallisticRemote:FireServer(rayClientRequest)
	MunitionController.processFireMunition(rayInfo)
end

function funcs.handleReplicationBallistic(rayInfo: MunitionRayInfo.ServerReplication)
	if rayInfo.Player then log:debug("Handling replication ballistic event from player {}", rayInfo.Player.Name) end

	local resolvedConfig: MunitionConfigUtil.DefaultType? = MunitionConfigUtil.getConfig(rayInfo.MunitionName)
	assert(resolvedConfig)

	local resolvedRayInfo: MunitionController.RayInfo = {
		RayId = rayInfo.RayId,
		MunitionConfig = resolvedConfig,
		Origin = rayInfo.Origin,
		InitOriginPos = rayInfo.InitOriginPos,
		InitDirection = rayInfo.InitDirection
	}

	local castBehavior = funcs.newBehavior(resolvedRayInfo)
	local initOrigin: Vector3 = rayInfo.InitOriginPos
	local initDir: Vector3 = rayInfo.InitDirection
	local modifiedBulletSpeed = (initDir * resolvedConfig.BallisticConfig.Speed)
	local projectile = (caster :: any):Fire(initOrigin, initDir, modifiedBulletSpeed, castBehavior) :: FastCastReduxTypes.ActiveCast
	projectile.UserData = { RayInfo = resolvedRayInfo }

	MunitionController.processFireMunition(resolvedRayInfo)
end

function funcs.handleBallisticRayUpdated(cast: FastCastReduxTypes.ActiveCast, segmentOrigin: Vector3, segmentDirection: Vector3, length: number, segmentVelocity: Vector3, cosmeticBulletObject: BasePart?)
	MunitionController.processRaySegment({
		RayInfo = cast.UserData.RayInfo :: MunitionController.RayInfo,
		OriginPos = segmentOrigin,
		DirectionVec = segmentDirection,
		Length = length
	})
end

function funcs.handleBallisticRayHit(cast: FastCastReduxTypes.ActiveCast, raycastResult: RaycastResult, segmentVelocity: Vector3, cosmeticBulletObject: BasePart?)
	local hitPos: Vector3 = raycastResult.Position
	local hit = raycastResult.Instance :: BasePart?
	cast.UserData.HitPos = hitPos
	cast.UserData.Hit = hit
end

function funcs.handleBallisticRayTerminated(cast: FastCastReduxTypes.ActiveCast)
	local rayInfo = cast.UserData.RayInfo :: MunitionController.RayInfo
	local rayHitInfo: MunitionController.RayHitInfo = {
		RayInfo = rayInfo,
		HitPos = cast.UserData.HitPos or rayInfo.InitOriginPos + (rayInfo.InitDirection * rayInfo.MunitionConfig.MaxDistance),
		Hit = cast.UserData.Hit :: BasePart?,
	}

	-- only show the hitmark and acknowledge the server if it's our ray
	if rayInfo.Player == player then
		verifyHitBallisticRemote:FireServer(rayInfo.RayId, rayHitInfo.HitPos, rayHitInfo.Hit)
		log:debug("Acknowledged server about ballistic ray hit {} rayId {}", rayInfo.MunitionConfig.MunitionName, rayInfo.RayId)
	end

	MunitionController.processRayEnd(rayHitInfo)
end

function funcs.newBehavior(rayInfo: MunitionController.RayInfo): FastCastReduxTypes.FastCastBehavior
	local config = rayInfo.MunitionConfig
	local castBehavior = FastCastRedux.newBehavior()
	castBehavior.MaxDistance = config.MaxDistance
	castBehavior.Acceleration = config.BallisticConfig.Gravity
	castBehavior.HighFidelitySegmentSize = config.BallisticConfig.HighFidelitySegmentSize
	castBehavior.RaycastParams = rayInfo.RaycastParams
	return castBehavior
end

caster.RayHit:Connect(funcs.handleBallisticRayHit)
caster.CastTerminating:Connect(funcs.handleBallisticRayTerminated)
caster.LengthChanged:Connect(funcs.handleBallisticRayUpdated)
replicationBallisticRemote.OnClientEvent:Connect(funcs.handleReplicationBallistic)
MunitionController.PreFire:connect(funcs.fireMunitionBallistic)

return module
