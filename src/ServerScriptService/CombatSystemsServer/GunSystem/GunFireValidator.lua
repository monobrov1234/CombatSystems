--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunStateService = require(script.Parent.GunStateService)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local MunitionSystemConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.MunitionSystemConfig)
local MunitionService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.MunitionService)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)

function funcs.validateGunFire(ray: RayTypeService.RayInfoNonValid): RaycastParams?
    if not ray.Player then return end
    local character = ray.Player.Character
	if not character then return end

    -- check that the player is holding a gun
	local tool: Tool? = character:FindFirstChildOfClass("Tool")
	if not tool or not GunUtil.validateGun(tool) then return end

    -- origin must be part of that gun
	assert(ray.Origin:IsDescendantOf(tool))

    local state = GunStateService.getGunState(tool)
	assert(state)
	assert(state.SharedState.MagSize > 0)

	local gunInfo = GunUtil.parseGunInfo(tool)
    -- verify that the munition we are firing is the config munition
	assert(gunInfo.Config.AmmoType == ray.MunitionConfig.MunitionName)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character, tool, MunitionSystemConfig.ProjectileFolder }
	return raycastParams
end

MunitionService.registerFireValidator(funcs.validateGunFire)

return module
