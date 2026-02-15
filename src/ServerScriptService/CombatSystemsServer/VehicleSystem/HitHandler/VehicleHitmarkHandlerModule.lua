local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObjectModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)
local DestructibleObjectService = require(ServerScriptService.CombatSystemsServer.GunSystem.DestructibleObjectService.DestructibleObjectServiceModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo))

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleHitHandler")

function funcs.handleHit(object: DestructibleObject.SelfObject, foundArmorInfo: DestructibleObjectUtil.ArmorInfo, damage: number, rayHitInfo: RayHitInfo)
	-- if its some weak bullet hit the vehicle, do not show the direction indicator
	if damage == 0 and (foundArmorInfo.ArmorType == "NoArmor" or "BulletProofArmor") then return end

	-- verify that this object is a vehicle
	local vehicle = object.object :: Instance
	if not vehicle:IsA("Model") then return end
	if not VehicleUtil.validateVehicle(vehicle) then return end

	local driverSeat = vehicle:FindFirstChildOfClass("VehicleSeat")
	assert(driverSeat)

	-- TODO: direction indicator event for client
	log:debug("Direction indicator called for {}", driverSeat.Occupant)
end

DestructibleObjectService.ObjectHit:connect(funcs.handleHit)

return module
