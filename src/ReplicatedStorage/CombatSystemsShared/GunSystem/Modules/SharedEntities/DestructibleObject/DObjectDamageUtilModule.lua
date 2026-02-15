local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObjectModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.DropoffUtilModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)) & {
	Hit: BasePart,
}

function module.canDamageObject(dObject: DestructibleObject.SelfObject, rayInfo: RayInfo)
	local config = rayInfo.MunitionConfig

	-- TODO: move this, make shared service
	-- teammate check
	if not config.CanDamageFriendly and rayInfo.Player.Team then
		-- find highest dobject in hierarchy, and check if it's a vehicle
		-- used to prevent damaging of nested dobjects in a vehicle (for example - turret shield on a truck)
		local objectAncestor: Instance = dObject.object
		local ancestor: Instance = dObject.object
		while ancestor do
			ancestor = ancestor.Parent
			if ancestor and DestructibleObjectUtil.validateObject(ancestor) then objectAncestor = ancestor end
		end

		if objectAncestor:IsA("Model") and VehicleUtil.validateVehicle(objectAncestor) and VehicleUtil.isVehicleFriendly(objectAncestor, rayInfo.Team) then
			return false
		end
	end

	return true
end

function module.calculateDirectDamage(rayHitInfo: RayHitInfo, hitPart: BasePart): number
	local rayInfo = rayHitInfo.RayInfo
	local config = rayInfo.MunitionConfig

	local totalDamage: number = DestructibleObjectUtil.getDamageForPart(config, hitPart)
	if config.EnableDropoff then
		totalDamage = DropoffUtil.calculateDropoff(
			totalDamage,
			(rayInfo.InitOriginPos - rayHitInfo.HitPos).Magnitude,
			config.DropoffConfig.DropoffStartDistance,
			config.DropoffConfig.DropoffEndDistance
		)
	end

	return totalDamage
end

return module
