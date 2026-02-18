--!strict

local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunStateService = require(script.Parent.GunStateServiceModule)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtilModule)
local MunitionService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionServiceModule)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.RayTypeServiceModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

function funcs.validateGunFire(rayInfo: RayTypeService.RayInfoNonValid): RaycastParams?
    if not rayInfo.Player then return end
    local character = rayInfo.Player.Character
	if not character then return end

    -- check that the player is holding a gun
	local tool: Tool? = character:FindFirstChildOfClass("Tool")
	if not tool or not GunUtil.validateGun(tool) then return end

    -- origin must be part of that gun
	assert(rayInfo.Origin:IsDescendantOf(tool))

    local state = GunStateService.getGunState(tool)
	assert(state)
	assert(state.SharedState.MagSize > 0)

	local gunInfo = GunUtil.parseGunInfo(tool)
    -- verify that the munition we are firing is the config munition
	assert(gunInfo.Config.GunConfig.AmmoType == rayInfo.MunitionConfig.MunitionName)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character, tool, GunSystemConfig.ProjectileFolder }
	return raycastParams
end

MunitionService.registerFireValidator(funcs.validateGunFire)