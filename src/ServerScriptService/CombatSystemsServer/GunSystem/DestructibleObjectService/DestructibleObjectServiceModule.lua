--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObjectModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)
local DObjectDamageService = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedServices.DamageCalculation.DObjectDamageServiceModule)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.DropoffUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.RayTypeServiceModule)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local MunitionHitService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionHitServiceModule)

-- ROBLOX OBJECTS
local explosionHitmark: RemoteEvent = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.ClientFX.ServerToClient.ExplosionHitmark

-- FINALS
local log: Logger.SelfObject = Logger.new("DestructibleObjectService")

export type ObjectHitInfo = {
	Object: DestructibleObject.SelfObject,
	Armor: DestructibleObjectUtil.ArmorInfo,
	Damage: number
}

-- PUBLIC EVENTS
module.ObjectHit = Signal.new() -- (ray: RayTypeService.RayInfo, rayHit: MunitionRayHitInfo.Common, objectHit: ObjectHitInfo)

-- INTERNAL FUNCTIONS
-- default hit handler, custom hit handlers need to cancel the event (return true) in order to stop this from executing
function funcs.handleDefaultHit(ray: RayTypeService.RayInfo, rayHit: MunitionRayHitInfo.Common, objectHit: ObjectHitInfo)
	if not objectHit.Object:isDestroyed() then return end
	objectHit.Object.object:Destroy()
end

function funcs.handleDirectHit(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.Common)
	assert(hit.Hit)
	local dObject: DestructibleObject.SelfObject? = DestructibleObject.fromInstanceChild(hit.Hit)
	if not dObject then return end
	local damage = DObjectDamageService.calculateDirectDamage(ray.MunitionConfig, ray.Body, hit)
	funcs.damageObject(ray, hit, dObject, damage)
end

function funcs.handleExplosionHit(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.Common, hits: MunitionHitService.ExplosionHits)
	assert(hit.Hit)
	local totalDamage = 0
	local foundObjects = {} :: { DestructibleObject.SelfObject }
	for _, explosionHit: MunitionHitService.ExplosionHitInfo in ipairs(hits) do
		-- skip if out of radius
		if explosionHit.ClosestBoundsDistance > ray.MunitionConfig.ExplosionConfig.Radius then continue end

		-- check that this part is not a descendant of previously found objects
		local isDescendant = false
		for _, object: DestructibleObject.SelfObject in ipairs(foundObjects) do
			if explosionHit.Part:IsDescendantOf(object.object) then
				isDescendant = true
				break
			end
		end
		if isDescendant then continue end

		local dObject = DestructibleObject.fromInstanceChild(explosionHit.Part)
		if not dObject then continue end
		if table.find(foundObjects, dObject) then continue end -- skip if already found
		table.insert(foundObjects, dObject)

		local damage = funcs.calculateExplosionDamage(ray, explosionHit)
		if funcs.damageObject(ray, hit, dObject, damage) then
			totalDamage += damage
		end
	end

	-- show the blue thingie for the player if their explosion hit anything
	if ray.Player and totalDamage > 0 then 
		explosionHitmark:FireClient(ray.Player, totalDamage, true)
	end
end

function funcs.damageObject(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.Common, object: DestructibleObject.SelfObject, damage: number): boolean
	assert(hit.Hit)
	if not DObjectDamageService.canDamageObject(object, ray.MunitionConfig, ray.Team) then return false end

	object:takeDamage(damage)

	local objectHitInfo: ObjectHitInfo = {
		Object = object,
		Armor = DestructibleObjectUtil.findFirstArmorInfo(hit.Hit),
		Damage = damage
	}
	module.ObjectHit:fire(ray, hit, objectHitInfo)
	return true
end

function funcs.calculateExplosionDamage(ray: RayTypeService.RayInfo, hit: MunitionHitService.ExplosionHitInfo): number
	local config = ray.MunitionConfig
	local totalDamage: number = DestructibleObjectUtil.getDamageForPart(config, hit.Part)
	log:debug("Calculated explosion damage for part {}, distance {}", hit.Part, hit.ClosestBoundsDistance)
	return DropoffUtil.calculateExplosionDropoff(
		totalDamage,
		hit.ClosestBoundsDistance,
		config.ExplosionConfig.DropoffStartRadius,
		config.ExplosionConfig.Radius
	)
end

module.ObjectHit:connect(funcs.handleDefaultHit, Signal.Priority.LOW) -- lower priority, execute after every custom handler
MunitionHitService.DirectHit:connect(funcs.handleDirectHit)
MunitionHitService.ExplosionHit:connect(funcs.handleExplosionHit)

return module
