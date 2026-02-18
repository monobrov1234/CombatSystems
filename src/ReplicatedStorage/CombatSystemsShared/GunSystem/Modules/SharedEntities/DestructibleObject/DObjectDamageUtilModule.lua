local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObjectModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.DropoffUtilModule)

function module.canDamageObject(dObject: DestructibleObject.SelfObject, config: MunitionConfigUtil.DefaultType, shootingTeam: Team)
	-- TODO: move this, make shared service
	-- teammate check
	if not config.CanDamageFriendly then
		-- find highest dobject in the hierarchy, and check if it's a vehicle
		-- used to prevent damaging of nested dobjects in a vehicle (for example - turret shield on a truck)
		local objectAncestor: Instance = dObject.object
		local ancestor: Instance? = dObject.object
		while ancestor do
			ancestor = ancestor.Parent
			if ancestor and DestructibleObjectUtil.validateObject(ancestor) then objectAncestor = ancestor end
		end

		if objectAncestor:IsA("Model") and VehicleUtil.validateVehicle(objectAncestor) and VehicleUtil.isVehicleFriendly(objectAncestor, shootingTeam) then
			return false
		end
	end

	return true
end

function module.calculateDirectDamage(config: MunitionConfigUtil.DefaultType, originPos: Vector3, hitPos: Vector3, hitPart: BasePart): number
	local totalDamage: number = DestructibleObjectUtil.getDamageForPart(config, hitPart)
	if config.EnableDropoff then
		totalDamage = DropoffUtil.calculateDropoff(
			totalDamage,
			(originPos - hitPos).Magnitude,
			config.DropoffConfig.DropoffStartDistance,
			config.DropoffConfig.DropoffEndDistance
		)
	end

	return totalDamage
end

return module
