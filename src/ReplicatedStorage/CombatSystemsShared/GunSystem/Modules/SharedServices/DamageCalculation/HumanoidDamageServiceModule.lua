local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.DropoffUtilModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)) & {
	Hit: BasePart,
}

-- PUBLIC API
function module.canDamageHumanoid(character: Model, humanoid: Humanoid, rayInfo: RayInfo)
	local config = rayInfo.MunitionConfig

	if humanoid.Health == 0 then return false end
	local player: Player? = Players:GetPlayerFromCharacter(character)
	if player then
		-- check if the shooter damaged itself
		if not config.CanDamageSelf then
			if player == rayInfo.Player then return false end
		end

		-- check if it's shooter teammate
		if not config.CanDamageFriendly and player ~= rayInfo.Player and rayInfo.Team then
			if player and rayInfo.Team == player.Team then return false end
		end

		-- check if the player is sitting in a vehicle that has ProtectedDriver or ProtectedPassenger set to true in the config
		local vehicle: VehicleUtil.VehicleInfo? = VehicleUtil.findPlayerCurrentVehicle(player)
		if vehicle then
			if vehicle.VehicleConfig.ProtectedDriver then
				-- check if the player is a driver
				if humanoid.SeatPart == vehicle.DriverSeat then return false end
			end

			if vehicle.VehicleConfig.ProtectedPassenger then
				-- check if the player is a passenger
				if humanoid.SeatPart ~= vehicle.DriverSeat then return false end
			end
		end
	end

	return true
end

function module.calculateDirectDamage(rayHitInfo: RayHitInfo): number
	local rayInfo = rayHitInfo.RayInfo
	local config = rayInfo.MunitionConfig

	local totalDamage = config.HumanoidDamage
	if config.EnableDropoff then
		totalDamage = DropoffUtil.calculateDropoff(
			totalDamage,
			(rayInfo.InitOriginPos - rayHitInfo.HitPos).Magnitude,
			config.DropoffConfig.DropoffStartDistance,
			config.DropoffConfig.DropoffEndDistance
		)
	end

	if rayHitInfo.Hit.Name == "Head" then
		totalDamage *= config.HeadshotMultiplier
	end

	return totalDamage
end

return module
