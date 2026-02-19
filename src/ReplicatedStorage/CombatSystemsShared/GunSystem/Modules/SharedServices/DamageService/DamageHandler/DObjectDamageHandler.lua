--!strict

local handler = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.DropoffUtilModule)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObject)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local DObjectService = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedServices.DObjectServiceModule)
local SharedDamageService = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedServices.DamageService.SharedDamageServiceModule)

function handler.canDamageHit(shooter: Player?, shooterTeam: Team?, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType): boolean
	local dObjectPart: BasePart = hit.Hit
	if not DestructibleObject.validateObject(dObjectPart) then return true end

	-- teammate check
	if not config.CanDamageFriendly and shooterTeam then
		-- find the root DObject in the hierarchy, and check if it is a vehicle
		-- used to prevent dealing damage to a nested DObjects in a vehicle (for example - turret shield on a truck)
		-- TODO: rework
		local objectAncestor: Instance = dObjectPart
		local ancestor: Instance? = dObjectPart
		while ancestor do
			ancestor = ancestor.Parent
			if ancestor and DestructibleObject.validateObject(ancestor) then 
				objectAncestor = ancestor 
			end
		end

		if objectAncestor:IsA("Model") and VehicleUtil.validateVehicle(objectAncestor) and VehicleUtil.isVehicleFriendly(objectAncestor, shooterTeam) then
			return false
		end
	end

	return true
end

function handler.calculateDirectDamage(ray: MunitionRayInfo.Common, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType): number?
	local dObjectPart: BasePart = hit.Hit
	if not DestructibleObject.validateObject(dObjectPart) then return nil end

	local totalDamage: number = DObjectService.getDamageForPart(config, dObjectPart)
	if config.EnableDropoff then
		totalDamage = DropoffUtil.calculateDropoff(
			totalDamage,
			(ray.InitOriginPos - hit.HitPos).Magnitude,
			config.DropoffConfig.DropoffStartDistance,
			config.DropoffConfig.DropoffEndDistance
		)
	end

	return totalDamage
end

SharedDamageService.registerDamageHandler(handler)

return {}
