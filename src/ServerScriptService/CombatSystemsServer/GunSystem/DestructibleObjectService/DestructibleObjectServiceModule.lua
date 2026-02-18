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
local RayTypeService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.RayTypeServiceModule)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local MunitionHitService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionHitServiceModule)

-- ROBLOX OBJECTS
local explosionHitmark: RemoteEvent = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.ClientFX.ServerToClient.ExplosionHitmark

-- FINALS
local log: Logger.SelfObject = Logger.new("DestructibleObjectService")

-- PUBLIC EVENTS
module.ObjectHit = Signal.new()

-- INTERNAL FUNCTIONS
-- default hit handler, custom hit handlers need to cancel the event (return true) in order to stop this from executing
function funcs.handleDefaultHit(object: DestructibleObject.SelfObject, foundArmorInfo: DestructibleObjectUtil.ArmorInfo, damage: number, rayHitInfo: RayTypeService.RayHitInfo)
	if not object:isDestroyed() then return end
	object.object:Destroy()
end

function funcs.handleDirectHit(rayHitInfo: RayTypeService.RayHitInfo)
	local dObject = DestructibleObject.fromInstanceChild(rayHitInfo.Hit)
	if not dObject then return end
	local damage = DObjectDamageService.calculateDirectDamage(rayHitInfo, rayHitInfo.Hit)
	funcs.damageObject(dObject, rayHitInfo, rayHitInfo.Hit, damage)
end

function funcs.handleExplosionHit(rayHitInfo: RayTypeService.RayHitInfo, hitParts: MunitionHitService.ExplosionHits)
	local totalDamage = 0
	local foundObjects = {} :: { DestructibleObject.SelfObject }
	for _, hit: MunitionHitService.ExplosionHitInfo in ipairs(hitParts) do
		-- skip if out of radius
		if hit.ClosestBoundsDistance > rayHitInfo.RayInfo.MunitionConfig.ExplosionConfig.Radius then continue end

		-- check that this part is not a descendant of previously found objects
		local isDescendant = false
		for _, object: DestructibleObject.SelfObject in ipairs(foundObjects) do
			if hit.Part:IsDescendantOf(object.object) then
				isDescendant = true
				break
			end
		end
		if isDescendant then continue end

		local dObject = DestructibleObject.fromInstanceChild(hit.Part)
		if not dObject then continue end
		if table.find(foundObjects, dObject) then continue end -- skip if already found
		table.insert(foundObjects, dObject)

		local damage = funcs.calculateExplosionDamage(rayHitInfo, hit)
		if funcs.damageObject(dObject, rayHitInfo, hit.Part, damage) then
			totalDamage += damage
		end
	end

	-- show blue thingie for the player if their explosion hit anything
	if rayHitInfo.RayInfo.Player and totalDamage > 0 then explosionHitmark:FireClient(rayHitInfo.RayInfo.Player, totalDamage, true) end
end

function funcs.damageObject(dObject: DestructibleObject.SelfObject, rayHitInfo: RayTypeService.RayHitInfo, hitPart: BasePart, damage: number): boolean
	if not DObjectDamageService.canDamageObject(dObject, rayHitInfo.RayInfo) then return false end

	dObject:takeDamage(damage)
	local foundArmorInfo: DestructibleObjectUtil.ArmorInfo = DestructibleObjectUtil.findFirstArmorInfo(hitPart)
	module.ObjectHit:fire(dObject, foundArmorInfo, damage, rayHitInfo)
	return true
end

function funcs.calculateExplosionDamage(rayHitInfo: RayTypeService.RayHitInfo, hit: MunitionHitService.ExplosionHitInfo): number
	local rayInfo = rayHitInfo.RayInfo
	local config = rayInfo.MunitionConfig
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
