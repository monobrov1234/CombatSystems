local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObjectModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.DropoffUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)

-- PUBLIC API
function module.canDamageObject(dObject: DestructibleObject.SelfObject, config: MunitionConfigUtil.DefaultType, shooterTeam: Team?)
	-- teammate check
	if not config.CanDamageFriendly and shooterTeam then
		-- find highest dobject in hierarchy, and check if it's a vehicle
		-- used to prevent damaging of nested dobjects in a vehicle (for example - turret shield on a truck)
		local objectAncestor: Instance = dObject.object
		local ancestor: Instance? = dObject.object
		while ancestor do
			ancestor = ancestor.Parent
			if ancestor and DestructibleObjectUtil.validateObject(ancestor) then objectAncestor = ancestor end
		end

		if objectAncestor:IsA("Model") and VehicleUtil.validateVehicle(objectAncestor) and VehicleUtil.isVehicleFriendly(objectAncestor, shooterTeam) then
			return false
		end
	end

	return true
end

function module.calculateDirectDamage(config: MunitionConfigUtil.DefaultType, ray: MunitionRayInfo.Common, hit: MunitionRayHitInfo.CommonFull): number
	local totalDamage: number = DestructibleObjectUtil.getDamageForPart(config, hit.Hit)
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

return module
