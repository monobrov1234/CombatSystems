--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local FastCastRedux = require(ReplicatedStorage.CombatSystemsShared.Libs.FastCastRedux)
local FastCastReduxTypes = require(ReplicatedStorage.CombatSystemsShared.Libs.FastCastRedux.TypeDefinitions)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo))

-- ROBLOX OBJECTS
local player = Players.LocalPlayer :: Player

local fireMunitionRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunition
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunition
local fireMunitionBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunitionBallistic
local verifyHitBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.VerifyHitBallistic
local replicationBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunitionBallistic

-- FINALS
local log: Logger.SelfObject = Logger.new("MunitionController")
local caster = FastCastRedux.new()

-- PUBLIC EVENTS
module.RayFired = Signal.new()
module.RaySegmentReached = Signal.new()
module.RayEnded = Signal.new()
module.Hit = Signal.new() -- (rayHitInfo: RayHitInfo) -> ()

-- PUBLIC API
function module.fireMunition(
	munitionName: string,
	origin: BasePart,
	directionVec: Vector3,
	raycastParams: RaycastParams?,
	spreadYawDeg: number,
	spreadPitchDeg: number
)
	local config = MunitionConfigUtil.getConfig(munitionName)
	assert(config, "Munition " .. munitionName .. " doesn't have config")

	-- spread calculation, client side
	if spreadYawDeg > 0 or spreadPitchDeg > 0 then
		local yaw = (math.random() - 0.5) * 2 * math.rad(spreadYawDeg)
		local pitch = (math.random() - 0.5) * 2 * math.rad(spreadPitchDeg)
		local originPos = origin.Position
		local cf = CFrame.lookAt(originPos, originPos + directionVec)
		cf = cf * CFrame.Angles(0, yaw, 0)
		cf = cf * CFrame.Angles(pitch, 0, 0)
		directionVec = cf.LookVector
	end

	local rayInfo: RayInfo = {
		Player = player,
		Team = player.Team,
		RayId = HttpService:GenerateGUID(),
		MunitionConfig = config,
		Origin = origin,
		InitOriginPos = origin.Position,
		InitDirection = directionVec,
		RaycastParams = raycastParams,
	}

	if config.EnableBallistics then
		funcs.fireMunitionBallistic(rayInfo)
	else
		funcs.fireMunitionRaycast(rayInfo)
	end
end

-- INTERNAL FUNCS
-- raycast firing
function funcs.fireMunitionRaycast(rayInfo: RayInfo)
	log:debug("Raycast-Firing munition {} with rayId {}", rayInfo.MunitionConfig.MunitionName, rayInfo.RayId)

	local config = rayInfo.MunitionConfig
	local initOrigin: Vector3 = rayInfo.InitOriginPos
	local initDir: Vector3 = rayInfo.InitDirection

	local result: RaycastResult? = workspace:Raycast(initOrigin, initDir * config.MaxDistance, rayInfo.RaycastParams)
	local hitPos: Vector3 = result and result.Position or initOrigin + initDir * config.MaxDistance
	local hit = result and result.Instance :: BasePart?
	local rayHitInfo: RayHitInfo = {
		RayInfo = rayInfo,
		HitPos = hitPos,
		Hit = hit,
	}

	fireMunitionRemote:FireServer(rayHitInfo)

	if hit then module.Hit:fire(rayHitInfo) end

	module.RayFired:fire(rayInfo)
	module.RaySegmentReached:fire(rayInfo, initOrigin, initDir, config.MaxDistance)
	module.RayEnded:fire(rayHitInfo)
end

function funcs.handleReplicationRaycast(rayHitInfo: RayHitInfo)
	local rayInfo = rayHitInfo.RayInfo
	if rayInfo.Player then log:debug("Handling replication raycast event from player {}", rayInfo.Player.Name) end

	-- because remote events erase metatables, we need to get the config again
	-- MunitionName is not resolved through a metatable so it's safe to use it
	rayInfo.MunitionConfig = MunitionConfigUtil.getConfig(rayInfo.MunitionConfig.MunitionName)
	assert(rayInfo.MunitionConfig)

	module.RayFired:fire(rayInfo)
	module.RaySegmentReached:fire(rayInfo, rayInfo.InitOriginPos, rayInfo.InitDirection, (rayHitInfo.HitPos - rayInfo.InitOriginPos).Magnitude)
	module.RayEnded:fire(rayHitInfo)
end

-- ballistic firing
function funcs.fireMunitionBallistic(rayInfo: RayInfo)
	log:debug("Ballistic-Firing munition {} with rayId {}", rayInfo.MunitionConfig.MunitionName, rayInfo.RayId)

	local config = rayInfo.MunitionConfig
	local initOrigin: Vector3 = rayInfo.InitOriginPos
	local initDir: Vector3 = rayInfo.InitDirection

	local castBehavior = funcs.newBehavior(rayInfo)
	local projectile = (caster :: any):Fire(initOrigin, initDir, initDir * config.BallisticConfig.Speed, castBehavior) :: FastCastReduxTypes.ActiveCast
	projectile.UserData = { RayInfo = rayInfo }

	fireMunitionBallisticRemote:FireServer(rayInfo)
	module.RayFired:fire(rayInfo)
end

function funcs.handleReplicationBallistic(rayInfo: RayInfo)
	if rayInfo.Player then log:debug("Handling replication ballistic event from player {}", rayInfo.Player.Name) end

	-- same as in handleReplicationRaycast
	rayInfo.MunitionConfig = MunitionConfigUtil.getConfig(rayInfo.MunitionConfig.MunitionName)
	assert(rayInfo.MunitionConfig)

	local config = rayInfo.MunitionConfig
	local initOrigin: Vector3 = rayInfo.InitOriginPos
	local initDir: Vector3 = rayInfo.InitDirection

	local castBehavior = funcs.newBehavior(rayInfo)
	local modifiedBulletSpeed = (initDir * config.BallisticConfig.Speed)
	local projectile = (caster :: any):Fire(initOrigin, initDir, modifiedBulletSpeed, castBehavior) :: FastCastReduxTypes.ActiveCast
	projectile.UserData = { RayInfo = rayInfo }

	module.RayFired:fire(rayInfo)
end

function funcs.handleBallisticRayUpdated(
	cast: FastCastReduxTypes.ActiveCast,
	segmentOrigin: Vector3,
	segmentDirection: Vector3,
	length: number,
	segmentVelocity: Vector3,
	cosmeticBulletObject: BasePart?
)
	module.RaySegmentReached:fire(cast.UserData.RayInfo, segmentOrigin, segmentDirection, length)
end

function funcs.handleBallisticRayHit(
	cast: FastCastReduxTypes.ActiveCast,
	raycastResult: RaycastResult,
	segmentVelocity: Vector3,
	cosmeticBulletObject: BasePart?
)
	local hitPos: Vector3 = raycastResult.Position
	local hit = raycastResult.Instance :: BasePart?
	cast.UserData.HitPos = hitPos
	cast.UserData.Hit = hit
end

function funcs.handleBallisticRayTerminated(cast: FastCastReduxTypes.ActiveCast)
	local rayInfo = cast.UserData.RayInfo :: RayInfo
	local hitPos: Vector3 = cast.UserData.HitPos or rayInfo.InitOriginPos + (rayInfo.InitDirection * rayInfo.MunitionConfig.MaxDistance)
	local hit = cast.UserData.Hit :: BasePart?

	local rayHitInfo: RayHitInfo = {
		RayInfo = rayInfo,
		HitPos = hitPos,
		Hit = hit,
	}

	if rayInfo.Player == player then -- only handle hitmark and acknowledge server if its our shot
		if hit then module.Hit:fire(rayHitInfo) end

		verifyHitBallisticRemote:FireServer(rayHitInfo)
		log:debug("Acknowledged server about ballistic ray hit {} rayId {}", rayInfo.MunitionConfig.MunitionName, rayInfo.RayId)
	end

	module.RayEnded:fire(rayHitInfo)
end

function funcs.newBehavior(rayInfo: RayInfo): FastCastReduxTypes.FastCastBehavior
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
replicationRemote.OnClientEvent:Connect(funcs.handleReplicationRaycast)
replicationBallisticRemote.OnClientEvent:Connect(funcs.handleReplicationBallistic)
return module
