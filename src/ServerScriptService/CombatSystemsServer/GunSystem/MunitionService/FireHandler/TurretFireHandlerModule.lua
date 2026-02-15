--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)
local TurretService = require(ServerScriptService.CombatSystemsServer.GunSystem.TurretService.TurretServiceModule)
local MunitionService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionServiceModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

function module.handleFireMunition(rayInfo: RayInfo, context: MunitionService.FireHandlerContext)
	if context.ResultRaycastParams then return end

	assert(rayInfo.Player)
	local turretInfo: TurretUtil.TurretInfo? = TurretService.getPlayerCurrentTurret(rayInfo.Player)
	if not turretInfo then return end
	assert(rayInfo.Origin:IsDescendantOf(turretInfo.TurretModel))

	context.ResultRaycastParams = TurretService._handleTurretFire(rayInfo)
end

MunitionService.ValidateFire:connect(module.handleFireMunition)

return module
