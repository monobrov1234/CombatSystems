--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionHitService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.MunitionHitService)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.DropoffUtil)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local SharedDamageService = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedServices.DamageService.SharedDamageService)

-- ROBLOX OBJECTS
local explosionHitmark: RemoteEvent = ReplicatedStorage.CombatSystemsShared.MunitionSystem.Events.ClientFX.ServerToClient.ExplosionHitmark

-- FINALS
local log: Logger.SelfObject = Logger.new("HumanoidHitHandler")

function funcs.handleDirectHit(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.CommonFull)
	local character: Model? = hit.Hit:FindFirstAncestorOfClass("Model")
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if not SharedDamageService.canDamageHit(ray.Player, ray.Team, hit, ray.MunitionConfig) then return end
	local damage: number? = SharedDamageService.calculateDirectDamage(ray.Body, hit, ray.MunitionConfig)
	assert(damage)
	funcs.damageHumanoid(character, humanoid, damage)
end

function funcs.handleExplosionHit(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.CommonFull, hitParts: MunitionHitService.ExplosionHits)
	local totalDamage = 0
	local foundCharacters = {} :: { Model }
	for _, explosionHit: MunitionHitService.ExplosionHitInfo in ipairs(hitParts) do
		-- check that this part is not a descendant of any previously found character
		local isDescendant = false
		for _, object: Model in ipairs(foundCharacters) do
			if explosionHit.Part:IsDescendantOf(object) then
				isDescendant = true
				break
			end
		end
		if isDescendant then continue end

		local character: Model? = explosionHit.Part:FindFirstAncestorOfClass("Model")
		if not character then continue end
		local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then continue end
		table.insert(foundCharacters, character)

		local damage = funcs.calculateExplosionDamage(ray, explosionHit)
		log:debug("Calculated explosion damage {} for part {}", damage, explosionHit.Part)

		if SharedDamageService.canDamageHit(ray.Player, ray.Team, hit, ray.MunitionConfig) then 
			funcs.damageHumanoid(character, humanoid, damage)
			totalDamage += damage
		end
	end

	-- show red thingie for the player if their explosion hit anything
	if ray.Player and totalDamage > 0 then 
		explosionHitmark:FireClient(ray.Player, totalDamage, false) 
	end
end

function funcs.damageHumanoid(character: Model, humanoid: Humanoid, damage: number)
	humanoid:TakeDamage(damage)
	-- TODO: hit indicator event for the target player
end

function funcs.calculateExplosionDamage(ray: RayTypeService.RayInfo, hit: MunitionHitService.ExplosionHitInfo): number
	local config = ray.MunitionConfig
	return DropoffUtil.calculateExplosionDropoff(
		config.ExplosionConfig.HumanoidDamage,
		hit.ClosestBoundsDistance,
		config.ExplosionConfig.DropoffStartRadius,
		config.ExplosionConfig.Radius
	)
end

MunitionHitService.DirectHit:connect(funcs.handleDirectHit)
MunitionHitService.ExplosionHit:connect(funcs.handleExplosionHit)

return module
