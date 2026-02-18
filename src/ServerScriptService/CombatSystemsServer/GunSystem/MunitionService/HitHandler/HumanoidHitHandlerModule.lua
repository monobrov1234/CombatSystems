--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionHitService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionHitServiceModule)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.RayTypeServiceModule)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.DropoffUtilModule)
local HumanoidDamageService = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedServices.DamageCalculation.HumanoidDamageServiceModule)

-- ROBLOX OBJECTS
local explosionHitmark: RemoteEvent = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.ClientFX.ServerToClient.ExplosionHitmark

-- FINALS
local log: Logger.SelfObject = Logger.new("HumanoidHitHandler")

function funcs.handleDirectHit(rayHitInfo: RayTypeService.RayHitInfo)
	assert(rayHitInfo.Hit)
	local character: Model? = rayHitInfo.Hit:FindFirstAncestorOfClass("Model")
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local damage = HumanoidDamageService.calculateDirectDamage(rayHitInfo)
	funcs.damageHumanoid(character, rayHitInfo, damage)
end

function funcs.handleExplosionHit(rayHitInfo: RayTypeService.RayHitInfo, hitParts: MunitionHitService.ExplosionHits)
	local totalDamage = 0
	local foundCharacters = {} :: { Model }
	for _, hit: MunitionHitService.ExplosionHitInfo in ipairs(hitParts) do
		-- check that this part is not a descendant of any previously found character
		local isDescendant = false
		for _, object: Model in ipairs(foundCharacters) do
			if hit.Part:IsDescendantOf(object) then
				isDescendant = true
				break
			end
		end
		if isDescendant then continue end

		local character: Model? = hit.Part:FindFirstAncestorOfClass("Model")
		if not character then continue end
		local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then continue end
		table.insert(foundCharacters, character)

		local damage = funcs.calculateExplosionDamage(rayHitInfo, hit)
		log:debug("Calculated explosion damage {} for part {}", damage, hit.Part)
		if funcs.damageHumanoid(character, rayHitInfo, damage) then
			totalDamage += damage
		end
	end

	-- show red thingie for the player if their explosion hit anything
	if rayHitInfo.RayInfo.Player and totalDamage > 0 then explosionHitmark:FireClient(rayHitInfo.RayInfo.Player, totalDamage, false) end
end

function funcs.damageHumanoid(character: Model, rayHitInfo: RayTypeService.RayHitInfo, damage: number): boolean
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid -- should never error
	if not HumanoidDamageService.canDamageHumanoid(character, humanoid, rayHitInfo.RayInfo) then return false end

	humanoid:TakeDamage(damage)
	-- TODO: hit indicator event for the target player
	return true
end

function funcs.calculateExplosionDamage(rayHitInfo: RayTypeService.RayHitInfo, hit: MunitionHitService.ExplosionHitInfo): number
	local rayInfo = rayHitInfo.RayInfo
	local config = rayInfo.MunitionConfig
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
