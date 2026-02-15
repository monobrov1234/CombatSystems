--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObjectModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)
local DestructibleObjectService = require(ServerScriptService.CombatSystemsServer.GunSystem.DestructibleObjectService.DestructibleObjectServiceModule)

type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo))

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleDestroyHandler")

function funcs.handleHit(object: DestructibleObject.SelfObject, foundArmorInfo: DestructibleObjectUtil.ArmorInfo, damage: number, rayHitInfo: RayHitInfo)
	if damage == 0 then return end
	if object:getHealth() > 0 then return end

	-- verify that this object is a vehicle
	local vehicle = object.object :: Instance
	if not vehicle:IsA("Model") then return end
	if not VehicleUtil.validateVehicle(vehicle) then return end

	-- kill the driver
	local seat: VehicleSeat = VehicleUtil.parseVehicleInfo(vehicle).DriverSeat
	if seat.Occupant then
		seat.Occupant:TakeDamage(150)
		log:trace("Killed the driver of a vehicle {}", vehicle.Name)
	end
end

DestructibleObjectService.ObjectHit:connect(funcs.handleHit) -- execute before every handler with normal priority so we can properly cancel the event

return module
