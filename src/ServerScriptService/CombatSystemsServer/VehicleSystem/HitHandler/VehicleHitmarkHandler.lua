local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DObjectHitService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.DObjectService.DObjectHitService)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleHitmarkHandler")

function funcs.handleHit(ray: RayTypeService.RayInfo, rayHit: MunitionRayHitInfo.Common, objectHit: DObjectHitService.ObjectHitInfo)
	-- if its some weak bullet hit the vehicle, do not show the direction indicator
	if objectHit.Damage == 0 and (objectHit.Armor.ArmorType == "NoArmor" or "BulletProofArmor") then return end

	-- verify that this object is a vehicle
	local vehicle = objectHit.Object.object :: Instance
	if not vehicle:IsA("Model") then return end
	if not VehicleUtil.validateVehicle(vehicle) then return end

	local driverSeat = vehicle:FindFirstChildOfClass("VehicleSeat")
	assert(driverSeat)

	-- TODO: direction indicator event for client
	log:debug("Direction indicator called for {}", driverSeat.Occupant)
end

DObjectHitService.ObjectHit:connect(funcs.handleHit)

return module
