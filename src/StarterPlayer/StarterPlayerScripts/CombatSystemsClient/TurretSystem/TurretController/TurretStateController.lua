--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local MunitionSystemConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.MunitionSystemConfig)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- IMPORTS INTERNAL
local TurretViewController = require(script.Parent.TurretViewController)

-- STATE
local turretInfo: TurretUtil.TurretInfo?
local turretState: TurretUtil.TurretStateInfo?
local fireRaycastParams: RaycastParams?

-- PUBLIC API
function module.getCurrentRaycastParams(): RaycastParams?
	return fireRaycastParams
end

function module.getCurrentClipSize(): number?
	if not turretState or not turretInfo then
		return nil
	end
	if turretState.UsingMainGun then
		return turretState.ClipSizeStorage[turretState.SelectedMunition] or nil
	else
		return turretState.CoaxClipSize
	end
end

function module.setClipSize(clipSize: number)
	assert(turretState)
	if turretState.UsingMainGun then
		turretState.ClipSizeStorage[turretState.SelectedMunition] = clipSize
	else
		turretState.CoaxClipSize = clipSize
	end
end

function module.getCurrentSelectedMunition(): string?
	if not turretState or not turretInfo then return nil end
	return turretState.UsingMainGun and turretState.SelectedMunition or turretInfo.TurretConfig.GunConfig.CoaxConfig.AmmoType
end

function module.getCurrentStoredAmmo(): number?
	if not turretState or not turretInfo then return nil end
	if turretState.UsingMainGun then
		return turretState.MunitionStorage[turretState.SelectedMunition] or 0
	else return turretState.CoaxAmmoSize end
end

function module.getFirerateRPM(): number?
	if not turretInfo or not turretState then return nil end
	return turretState.UsingMainGun and turretInfo.TurretConfig.GunConfig.FirerateRPM or turretInfo.TurretConfig.GunConfig.CoaxConfig.FirerateRPM
end

-- INTERNAL FUNCTIONS
function funcs.handleTurretViewSet(newTurretInfo: TurretUtil.TurretInfo, customRayFilters: { Instance }?)
	turretInfo = newTurretInfo
	fireRaycastParams = funcs.buildRaycastParams(customRayFilters)
end

function funcs.handleTurretViewCleared()
	turretInfo = nil
	turretState = nil
	fireRaycastParams = nil
end

function funcs.handleTurretStateChanged(newTurretState: TurretUtil.TurretStateInfo)
	turretState = newTurretState
end

function funcs.buildRaycastParams(customRayFilters: { Instance }?): RaycastParams
	assert(turretInfo)
	assert(player.Character)

	local filterDescendantsInstances: { Instance } = { turretInfo.TurretModel, player.Character, MunitionSystemConfig.ProjectileFolder }
	if customRayFilters then
		for _, instance: Instance in ipairs(customRayFilters) do
			table.insert(filterDescendantsInstances, instance)
		end
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	return raycastParams
end

-- SUBSCRIPTIONS
TurretViewController.TurretViewSet:connect(funcs.handleTurretViewSet, Signal.Priority.HIGH)
TurretViewController.TurretStateChanged:connect(funcs.handleTurretStateChanged, Signal.Priority.HIGH)
TurretViewController.TurretViewCleared:connect(funcs.handleTurretViewCleared, Signal.Priority.HIGH)

return module
