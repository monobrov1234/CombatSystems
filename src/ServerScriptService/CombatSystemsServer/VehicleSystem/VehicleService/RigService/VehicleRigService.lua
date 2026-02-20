--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local TurretRigService = require(ServerScriptService.CombatSystemsServer.TurretSystem.RigService.TurretRigService)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local RigUtil = require(ServerScriptService.CombatSystemsServer.Utils.RigUtil)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.DestructibleObjectConfig)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- IMPORTS INTERNAL
local VehicleRigUtil = require(script.Parent.VehicleRigUtil)

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleRigService")

PhysicsService:RegisterCollisionGroup("Vehicle")
PhysicsService:RegisterCollisionGroup("Wheel")
PhysicsService:CollisionGroupSetCollidable("Wheel", "Wheel", false)
PhysicsService:CollisionGroupSetCollidable("Wheel", "Vehicle", false)

-- PUBLIC EVENTS
module.DriverPromptTriggered = Signal.new() -- (player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt)
module.PassengerPromptTriggered = Signal.new() -- (player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt, seat: Seat)
module.VehicleRigged = Signal.new() -- (vehicleInfo: VehicleUtil.VehicleInfo)
module.TypeRigRequested = Signal.new() -- (vehicle: Model, vehicleConfig, chassis: BasePart, totalMass: number)

-- PUBLIC API
function module.rigVehicles(instance: Instance)
	local vehicles: { VehicleUtil.VehicleInfo } = VehicleUtil.findDescendantVehicles(instance)
	for _, info in ipairs(vehicles) do
		module.rigVehicle(info)
	end
end

function module.rigVehicle(vehicleInfo: VehicleUtil.VehicleInfoNotRigged): VehicleUtil.VehicleInfo
	local vehicle = vehicleInfo.VehicleModel
	local config = vehicleInfo.VehicleConfig

	log:debug("Rigging vehicle {}", vehicleInfo.VehicleModel.Name)

	local chassis = vehicle.PrimaryPart
	assert(chassis, "Vehicle primary part not found")

	if config.PhysicalConfig.AutoRig then
		chassis.RootPriority = 127

		for _, descendant: Instance in ipairs(vehicle:GetDescendants() :: { Instance }) do
			if not descendant:IsA("BasePart") then continue end
			if descendant == chassis then continue end

			descendant.CollisionGroup = "Vehicle"

			if descendant:FindFirstChildOfClass("Weld") or descendant:FindFirstChildOfClass("WeldConstraint") then continue end
			RigUtil.weld(descendant, chassis)
		end

		local totalMass = config.PhysicalConfig.Mass * 1000
		for _, part: Instance in ipairs(vehicle:GetDescendants()) do
			if not part:IsA("BasePart") then continue end
			part.CustomPhysicalProperties = part:HasTag("Wheel") and config.WheelConfig.PhysicalProperties or config.PhysicalConfig.DefaultPhysicalProperties
			part.Massless = false
			totalMass += part.Mass
		end

		log:debug("Vehicle total mass: {}", totalMass)

		assert(config.ConfigType)
		module.TypeRigRequested:fire(vehicle, config, chassis, totalMass)

		local wheels: { BasePart } = module.findWheels(vehicle)
		for _, wheel in ipairs(wheels) do
			wheel.CollisionGroup = "Wheel"
		end

		local centerOfMass = VehicleRigUtil.createCenterOfMass(config, wheels)
		centerOfMass.CFrame = chassis.CFrame
		centerOfMass.Parent = vehicle
		RigUtil.weld(centerOfMass, chassis)

		if not vehicle:HasTag(DestructibleObjectConfig.Tag) then vehicle:AddTag(DestructibleObjectConfig.Tag) end

		if not vehicle:GetAttribute(DestructibleObjectConfig.MaxHealthAttribute) then
			vehicle:SetAttribute(DestructibleObjectConfig.MaxHealthAttribute, config.MaxHealth)
		end

		if not vehicle:GetAttribute(DestructibleObjectConfig.HealthAttribute) then
			vehicle:SetAttribute(DestructibleObjectConfig.HealthAttribute, config.MaxHealth)
		end
	end

	if config.PhysicalConfig.AutoRigTurrets then
		TurretRigService.rigTurrets(vehicle)
	end
	TurretRigService.promptTurrets(vehicle)

	local info: VehicleUtil.VehicleInfo = VehicleUtil.parseVehicleInfo(vehicleInfo.VehicleModel)

	local driverSeat: VehicleSeat = vehicleInfo.DriverSeat
	local passengerSeats: { Seat } = VehicleUtil.findVehiclePassengerSeats(vehicleInfo.VehicleModel)

	local driverPrompt: ProximityPrompt = VehicleSystemConfig.BasePrompt:Clone()
	driverPrompt.ObjectText = info.VehicleModel.Name
	driverPrompt.ActionText = "Drive"
	driverPrompt.RequiresLineOfSight = false
	driverPrompt.HoldDuration = info.VehicleConfig.SeatConfig.DriverPromptHoldDuration
	driverPrompt.MaxActivationDistance = info.VehicleConfig.SeatConfig.PassengerPromptDistance
	driverPrompt.Triggered:Connect(function(player: Player)
		module.DriverPromptTriggered:fire(player, info, driverPrompt)
	end)
	driverPrompt.Parent = driverSeat

	for _, seat: Seat in ipairs(passengerSeats) do
		local passengerPrompt: ProximityPrompt = VehicleSystemConfig.BasePrompt:Clone()
		passengerPrompt.ObjectText = (seat:GetAttribute("SeatName") :: string?) or info.VehicleModel.Name
		passengerPrompt.ActionText = "Sit"
		passengerPrompt.KeyboardKeyCode = Enum.KeyCode.Q
		passengerPrompt.RequiresLineOfSight = false
		passengerPrompt.HoldDuration = info.VehicleConfig.SeatConfig.PassengerPromptHoldDuration
		passengerPrompt.MaxActivationDistance = info.VehicleConfig.SeatConfig.PassengerPromptDistance
		passengerPrompt.Triggered:Connect(function(player: Player)
			module.PassengerPromptTriggered:fire(player, info, passengerPrompt, seat)
		end)
		passengerPrompt.Parent = seat
	end

	local soundConfig = config.DecorConfig.SoundsConfig
	funcs.putSound("Enter", soundConfig.Enter, vehicleInfo.DriverSeat)
	funcs.putSound("Dismount", soundConfig.Dismount, vehicleInfo.DriverSeat)
	funcs.putSound("EngineIdle", soundConfig.EngineIdle, vehicleInfo.EnginePart)
	funcs.putSound("EngineMove", soundConfig.EngineMove, vehicleInfo.EnginePart)

	info.DriverSeat.HeadsUpDisplay = false
	module.VehicleRigged:fire(info)
	return info
end

function module.findWheels(vehicleModel: Model): { BasePart }
	local wheels = {} :: { BasePart }

	for _, wheel: Instance in ipairs(vehicleModel:GetDescendants()) do
		if wheel:IsA("BasePart") and wheel:HasTag("Wheel") then table.insert(wheels, wheel :: BasePart) end
	end

	return wheels
end

-- INTERNAL FUNCTIONS
function funcs.putSound(name: string, sound: Sound?, parent: Instance)
	if not sound then return end

	local clone = sound:Clone()
	clone.Name = name
	clone.Parent = parent
end

return module
