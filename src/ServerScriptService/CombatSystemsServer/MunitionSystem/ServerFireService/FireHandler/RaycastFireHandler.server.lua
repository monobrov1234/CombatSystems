local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.MunitionService)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local ServerFireService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.ServerFireService.ServerFireService)

-- FINALS
local _log: Logger.SelfObject = Logger.new("RaycastFireHandlerServer")

-- INTERNAL FUNCTIONS
function funcs.handlePreFire(ray: RayTypeService.RayInfo)
	if ray.MunitionConfig.EnableBallistics then return end

    local result: RaycastResult? = workspace:Raycast(ray.Origin.Position, ray.Body.InitDirection * ray.MunitionConfig.MaxDistance, ray.RaycastParams)
    if not result then return end

    MunitionService.processMunitionFire(ray)
    MunitionService.processMunitionHit(ray, {
        HitPos = result.Position,
        Hit = result.Instance :: BasePart?
    })
end

ServerFireService.PreFire:connect(funcs.handlePreFire)