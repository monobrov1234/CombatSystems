--!strict

local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurretStateService = require(script.Parent.TurretStateServiceModule)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local TurretConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.TurretConfigUtilModule)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)
local MunitionService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionServiceModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

function funcs.validateTurretFire(rayInfo: MunitionRayInfo.Type): RaycastParams?
    if not rayInfo.Player then return nil end -- should have player to get a turret he is manning
    
	local turretInfo: TurretUtil.TurretInfo? = TurretStateService.getPlayerCurrentTurret(rayInfo.Player)
	if not turretInfo then return nil end -- turret not found, skip validation
    local turretConfig: TurretConfigUtil.DefaultType = turretInfo.TurretConfig
    local munitionName = rayInfo.MunitionConfig.MunitionName

    -- origin must be part of a turret
	assert(rayInfo.Origin:IsDescendantOf(turretInfo.TurretModel))

	local player: Player = rayInfo.Player
	assert(player.Character)

	local state = TurretStateService.getTurretState(turretInfo)
    assert(state) -- should not happen, if happens it means that setTurretView in TurretService was not called by some reason

	-- current turret config must have the munition we are firing
	if state.UsingMainGun then
		local ok = false
		for _, data in ipairs(turretConfig.GunConfig.AmmoTypes) do
			if data.name == munitionName then
				ok = true
				break
			end
		end
		assert(ok)
	else
		assert(turretConfig.GunConfig.CoaxConfig.AmmoType == munitionName)
	end

    -- validate that mag is not empty
    if state.UsingMainGun then
		assert(state.ClipSizeStorage[munitionName] > 0)
	else
		assert(state.CoaxClipSize > 0)
	end

	-- raycast params calculation
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	-- by default we ignore character, all projectiles, and the turret model
	local filterDescendantsInstances = { player.Character,  GunSystemConfig.ProjectileFolder, turretInfo.TurretModel } :: { Instance }

	-- insert additional instances provided by SetTurretHandler
    local raycastBlacklist = TurretStateService.getPlayerRaycastBlacklist(player)
	if raycastBlacklist then
		for _, instance: Instance in ipairs(raycastBlacklist) do
			table.insert(filterDescendantsInstances, instance)
		end
	end

	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	return raycastParams
end

MunitionService.registerFireValidator(funcs.validateTurretFire)