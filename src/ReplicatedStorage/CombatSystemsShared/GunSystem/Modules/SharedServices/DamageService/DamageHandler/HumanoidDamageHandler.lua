--!strict

local handler = {} 
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.DropoffUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local SharedDamageService = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedServices.DamageService.SharedDamageServiceModule)

function handler.canDamageHit(shooter: Player?, shooterTeam: Team?, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType): boolean
	local character: Model? = hit.Hit:FindFirstAncestorOfClass("Model")
	if not character then return true end
	local humanoid: Humanoid? = funcs.verifyCharacterHumanoid(character)
	if not humanoid then return true end
	local targetPlayer: Player? = Players:GetPlayerFromCharacter(character)
	if not targetPlayer then return true end

	-- check if the shooter damaged himself
	if not config.CanDamageSelf then
		if targetPlayer == shooter then return false end
	end

	-- check if it's a shooter teammate
	if not config.CanDamageFriendly and targetPlayer ~= shooter and shooterTeam then
		if shooterTeam == targetPlayer.Team then return false end
	end

	-- check if the targetPlayer is sitting in a vehicle that has ProtectedDriver or ProtectedPassenger set to true in the config
	local vehicle: VehicleUtil.VehicleInfo? = VehicleUtil.findPlayerCurrentVehicle(targetPlayer)
	if vehicle then
		if vehicle.VehicleConfig.ProtectedDriver then
			-- check if the targetPlayer is a driver
			if humanoid.SeatPart == vehicle.DriverSeat then return false end
		end

		if vehicle.VehicleConfig.ProtectedPassenger then
			-- check if the targetPlayer is a passenger
			if humanoid.SeatPart ~= vehicle.DriverSeat then return false end
		end
	end

	return true
end

function handler.calculateDirectDamage(ray: MunitionRayInfo.Common, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType): number?
	local character: Model? = hit.Hit:FindFirstAncestorOfClass("Model")
	if not character then return nil end
	local humanoid: Humanoid? = funcs.verifyCharacterHumanoid(character)
	if not humanoid then return nil end

	local totalDamage = config.HumanoidDamage
	if config.EnableDropoff then
		totalDamage = DropoffUtil.calculateDropoff(
			totalDamage,
			(ray.InitOriginPos - hit.HitPos).Magnitude,
			config.DropoffConfig.DropoffStartDistance,
			config.DropoffConfig.DropoffEndDistance
		)
	end

	if hit.Hit.Name == "Head" then
		totalDamage *= config.HeadshotMultiplier
	end

	return totalDamage
end

function funcs.verifyCharacterHumanoid(character: Model): Humanoid?
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	if humanoid.Health == 0 then
		return nil -- invalid dead humanoid
	else return humanoid end
end

SharedDamageService.registerDamageHandler(handler :: SharedDamageService.DamageHandler)

return {}
