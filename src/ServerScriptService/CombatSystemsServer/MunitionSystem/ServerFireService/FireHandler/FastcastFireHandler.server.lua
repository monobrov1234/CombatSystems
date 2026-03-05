local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.MunitionService)
local FastCastRedux = require(ReplicatedStorage.CombatSystemsShared.Libs.FastCastRedux)
local FastCastReduxTypes = require(ReplicatedStorage.CombatSystemsShared.Libs.FastCastRedux.TypeDefinitions)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local ServerFireService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.ServerFireService.ServerFireService)

-- FINALS
local _log: Logger.SelfObject = Logger.new("FastcastFireHandlerServer")
local caster = FastCastRedux.new()

-- INTERNAL FUNCTIONS
function funcs.handlePreFire(ray: RayTypeService.RayInfo)
	if not ray.MunitionConfig.EnableBallistics then return end
    caster.Fire(ray.Origin.Position, ray.Body.InitDirection, ray.Body.InitDirection * ray.MunitionConfig.MaxDistance, funcs.newBehavior(ray))
    MunitionService.processMunitionFire(ray)
end

function funcs.handleBallisticRayHit(cast: FastCastReduxTypes.ActiveCast, raycastResult: RaycastResult, segmentVelocity: Vector3, cosmeticBulletObject: BasePart?)
    local ray = cast.UserData.RayInfo :: RayTypeService.RayInfo
	local hitPos: Vector3 = raycastResult.Position
	local hit = raycastResult.Instance :: BasePart?

    MunitionService.processMunitionHit(ray, {
        HitPos = hitPos,
        Hit = hit
    })
end

function funcs.newBehavior(rayInfo: RayTypeService.RayInfo): FastCastReduxTypes.FastCastBehavior
	local config = rayInfo.MunitionConfig
	local castBehavior = FastCastRedux.newBehavior()
	castBehavior.MaxDistance = config.MaxDistance
	castBehavior.Acceleration = config.BallisticConfig.Gravity
	castBehavior.HighFidelitySegmentSize = config.BallisticConfig.HighFidelitySegmentSize
	castBehavior.RaycastParams = rayInfo.RaycastParams
	return castBehavior
end

caster.RayHit:Connect(funcs.handleBallisticRayHit)
ServerFireService.PreFire:connect(funcs.handlePreFire)