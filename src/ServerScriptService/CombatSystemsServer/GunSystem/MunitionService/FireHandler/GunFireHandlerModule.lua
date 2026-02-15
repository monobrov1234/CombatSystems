--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GunConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunConfig)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtilModule)
local GunService = require(ServerScriptService.CombatSystemsServer.GunSystem.GunService.GunServiceModule)
local MunitionService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionServiceModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

function module.handleFireMunition(rayInfo: RayInfo, context: MunitionService.FireHandlerContext)
	if context.ResultRaycastParams then return end

	assert(rayInfo.Player)
	local character = rayInfo.Player.Character
	if not character then return end
	local tool: Tool? = character:FindFirstChildOfClass("Tool")
	if not tool or not GunUtil.validateGun(tool) then return end

	assert(rayInfo.Origin:IsDescendantOf(tool))
	context.ResultRaycastParams = GunService.handleGunFire(rayInfo, tool)
end

MunitionService.ValidateFire:connect(module.handleFireMunition)

return module
