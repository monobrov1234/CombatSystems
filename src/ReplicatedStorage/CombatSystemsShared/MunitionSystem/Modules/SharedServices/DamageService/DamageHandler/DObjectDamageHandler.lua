--!strict

local handler = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.DropoffUtil)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.DestructibleObject.DestructibleObject)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local DObjectService = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedServices.DObjectService)
local SharedDamageService = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedServices.DamageService.SharedDamageService)

function handler.canDamageHit(shooter: Player?, shooterTeam: Team?, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType): boolean
	local dObject: DestructibleObject.SelfObject? = DestructibleObject.fromInstanceChild(hit.Hit)
	if not dObject then return true end

	-- teammate check
	if not config.CanDamageFriendly and shooterTeam then
		-- find the root DObject in the hierarchy, and check if it is a vehicle
		-- used to prevent dealing damage to a nested DObjects in a vehicle (for example - turret shield on a truck)
		-- TODO: rework
		local objectAncestor: Instance = dObject.object
		local ancestor: Instance? = dObject.object
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
	local dObject: DestructibleObject.SelfObject? = DestructibleObject.fromInstanceChild(hit.Hit)
	if not dObject then return nil end
	
	local totalDamage: number = DObjectService.getDamageForPart(config, dObject.object :: BasePart)
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
