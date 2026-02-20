--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local DObjectHitService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.DObjectService.DObjectHitService)

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleKillOnDestroyHandler")

-- INTERNAL FUNCTIONS
function funcs.handleHit(ray: RayTypeService.RayInfo, rayHit: MunitionRayHitInfo.Common, objectHit: DObjectHitService.ObjectHitInfo)
	if objectHit.Damage == 0 then return end
	if objectHit.Object:getHealth() > 0 then return end

	local vehicle = objectHit.Object.object :: Instance
	if not vehicle:IsA("Model") then return end
	if not VehicleUtil.validateVehicle(vehicle) then return end

	local seat: VehicleSeat = VehicleUtil.parseVehicleInfo(vehicle).DriverSeat
	if seat.Occupant then
		seat.Occupant:TakeDamage(150)
		log:trace("Killed the driver of a vehicle {}", vehicle.Name)
	end
end

-- SUBSCRIPTIONS
DObjectHitService.ObjectHit:connect(funcs.handleHit)

return module
