--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSystemConfig)
local VehicleConfigUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleConfigUtilModule)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Configs.DestructibleObjectConfig)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.DestructibleObject.DestructibleObject)

-- FINALS
export type VehicleInfoNotRigged = {
	VehicleModel: Model,
	DriverSeat: VehicleSeat,
	VehicleConfig: VehicleConfigUtil.DefaultType,
	SystemParts: Model,
	EnginePart: BasePart,
	DismountPart: BasePart,
	Camera: BasePart,
}
export type VehicleInfo = VehicleInfoNotRigged & {
	VehicleObject: DestructibleObject.SelfObject,
}

function module.validateVehicle(vehicleModel: Model): boolean
	return vehicleModel:HasTag(VehicleSystemConfig.Tag) and DestructibleObject.validateObject(vehicleModel)
end

function module.validatePassengerSeat(seat: Seat): boolean
	return seat:HasTag(VehicleSystemConfig.PassengerSeatTag)
end

-- for parsing rigged vehicles
function module.parseVehicleInfo(vehicleModel: Model): VehicleInfo
	local vehicleInfo: VehicleInfoNotRigged = module.parseVehicleInfoNonRig(vehicleModel)

	-- verify that vehicle is destructible object
	local vehicleObject: DestructibleObject.SelfObject? = DestructibleObject.fromInstance(vehicleModel)
	assert(vehicleObject, "Vehicle is not a destructible object")

	return {
		VehicleModel = vehicleInfo.VehicleModel,
		DriverSeat = vehicleInfo.DriverSeat,
		VehicleObject = vehicleObject,
		VehicleConfig = vehicleInfo.VehicleConfig,
		SystemParts = vehicleInfo.SystemParts,
		EnginePart = vehicleInfo.EnginePart,
		DismountPart = vehicleInfo.DismountPart,
		Camera = vehicleInfo.Camera,
	}
end

-- for parsing non-rigged vehicles
function module.parseVehicleInfoNonRig(vehicleModel: Model): VehicleInfoNotRigged
	local driverSeat = vehicleModel:FindFirstChildOfClass("VehicleSeat")
	assert(driverSeat, "Vehicle doesn't have driver seat")

	-- find config
	local config = VehicleConfigUtil.getConfig(vehicleModel)
	assert(config, "Vehicle doesn't have config")

	-- find system parts
	local systemParts = vehicleModel:FindFirstChild("SystemParts") :: Model?
	assert(systemParts and systemParts:IsA("Model"), "Vehicle doesn't have SystemParts")

	-- find engine part
	local enginePart = systemParts:FindFirstChild("Engine") :: BasePart?
	assert(enginePart and enginePart:IsA("BasePart"), "Vehicle doesn't have Engine part")

	-- find dismount part
	local dismountPart: BasePart? = vehicleModel:FindFirstChild("DismountPart") :: BasePart?
	assert(dismountPart and dismountPart:IsA("BasePart"), "Vehicle doesn't have DismountPart")

	-- find Camera part
	local camera: BasePart? = vehicleModel:FindFirstChild("Camera") :: BasePart?
	assert(camera and camera:IsA("BasePart"), "Vehicle doesn't have Camera part")

	return {
		VehicleModel = vehicleModel,
		DriverSeat = driverSeat,
		VehicleConfig = config,
		SystemParts = systemParts,
		EnginePart = enginePart,
		DismountPart = dismountPart,
		Camera = camera,
	}
end

function module.isVehicleFriendly(vehicleModel: Model, team: Team): boolean
	local vehicleTeam = vehicleModel:GetAttribute(VehicleSystemConfig.TeamAttribute) :: string?
	return team.Name == vehicleTeam
end

-- will return vehicle info of vehicle that player currently is sitting in
-- NOTE: player can be BOTH DRIVER OR PASSENGER
function module.findPlayerCurrentVehicle(player: Player): VehicleInfo?
	local character: Model? = player.Character
	if not character then return nil end
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local seat = humanoid.SeatPart
	if not seat then return nil end

	local currentAncestor: Instance? = seat.Parent
	if not currentAncestor then return nil end
	while currentAncestor do
		if currentAncestor:IsA("Model") and module.validateVehicle(currentAncestor) and currentAncestor:HasTag(DestructibleObjectConfig.Tag) then break end
		currentAncestor = currentAncestor.Parent
	end

	local vehicleModel = currentAncestor :: Model
	if not vehicleModel then return nil end

	return module.parseVehicleInfo(vehicleModel)
end

function module.findDescendantVehicles(instance: Instance): { VehicleInfo }
	local found = {} :: { VehicleInfo }
	for _, descendant: Instance in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Model") and module.validateVehicle(descendant) then table.insert(found, module.parseVehicleInfo(descendant)) end
	end
	return found
end

function module.findVehiclePassengerSeats(vehicle: Model): { Seat }
	local passengerSeats = {} :: { Seat }
	for _, descendant: Instance in ipairs(vehicle:GetDescendants()) do
		if descendant:IsA("Seat") and module.validatePassengerSeat(descendant) then table.insert(passengerSeats, descendant :: Seat) end
	end
	return passengerSeats
end

return module
