--!strict

local module = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurretRigService = require(ServerScriptService.CombatSystemsServer.TurretSystem.RigService.TurretRigService)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local RigUtil = require(ServerScriptService.CombatSystemsServer.Utils.RigUtil)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.DestructibleObjectConfig)

-- IMPORTS INTERNAL
local VehicleRigUtil = require(script.Parent.VehicleRigUtil)

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleRigService")

type VehicleRigger = {
	rigVehicle: (vehicle: Model, vehicleConfig: {}, chassis: BasePart, totalMass: number) -> (),
}
local riggerMapping: { [string]: VehicleRigger } = {
	["Normal"] = require(script.Parent.Impl.NormalVehicleRigger) :: VehicleRigger,
	["Tracked"] = require(script.Parent.Impl.TrackedVehicleRigger) :: VehicleRigger,
}

-- INTERNAL API (used by VehicleServiceModule)
module.DriverPromptTriggered = function() end :: (player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt) -> ()
module.PassengerPromptTriggered = function() end :: (player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt, seat: Seat) -> ()

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
		chassis.RootPriority = 127 -- chassis is always main part in assembly

		-- weld everything to chassis, implementations should unweld back what they need
		for _, descendant: Instance in ipairs(vehicle:GetDescendants() :: { Instance }) do
			if not descendant:IsA("BasePart") then continue end
			if descendant == chassis then continue end

			-- set collision groups
			descendant.CollisionGroup = "Vehicle"

			-- if the descendant has any child welds, ignore and do not weld it
			if descendant:FindFirstChildOfClass("Weld") or descendant:FindFirstChildOfClass("WeldConstraint") then continue end
			RigUtil.weld(descendant, chassis)
		end

		-- calculate total mass for suspension
		local totalMass = config.PhysicalConfig.Mass * 1000
		for _, part: Instance in ipairs(vehicle:GetDescendants()) do
			if not part:IsA("BasePart") then continue end
			part.CustomPhysicalProperties = part:HasTag("Wheel") and config.WheelConfig.PhysicalProperties or config.PhysicalConfig.DefaultPhysicalProperties
			part.Massless = false
			totalMass += part.Mass
		end

		log:debug("Vehicle total mass: {}", totalMass)

		-- type specific handling
		assert(config.ConfigType)
		local rigger = riggerMapping[config.ConfigType]
		assert(rigger, "Rigger implementation for vehicle type " .. config.ConfigType .. " not found")
		rigger.rigVehicle(vehicle, config, chassis, totalMass)

		-- set wheel collision groups, set their correct rotation
		local wheels: { BasePart } = module.findWheels(vehicle)
		for _, wheel in ipairs(wheels) do
			wheel.CollisionGroup = "Wheel"
		end

		-- create center of mass
		local centerOfMass = VehicleRigUtil.createCenterOfMass(config, wheels)
		centerOfMass.CFrame = chassis.CFrame
		centerOfMass.Parent = vehicle
		RigUtil.weld(centerOfMass, chassis)

		-- add destructible object info if not already there
		if not vehicle:HasTag(DestructibleObjectConfig.Tag) then vehicle:AddTag(DestructibleObjectConfig.Tag) end

		if not vehicle:GetAttribute(DestructibleObjectConfig.MaxHealthAttribute) then
			vehicle:SetAttribute(DestructibleObjectConfig.MaxHealthAttribute, config.MaxHealth)
		end

		if not vehicle:GetAttribute(DestructibleObjectConfig.HealthAttribute) then
			vehicle:SetAttribute(DestructibleObjectConfig.HealthAttribute, config.MaxHealth)
		end
	end

	if config.PhysicalConfig.AutoRigTurrets then -- rig every turret if AutoWeldTurrets is enabled
		TurretRigService.rigTurrets(vehicle)
	end
	TurretRigService.promptTurrets(vehicle) -- no matter what, turrets should be prompted even if they're custom rigged

	local info: VehicleUtil.VehicleInfo = VehicleUtil.parseVehicleInfo(vehicleInfo.VehicleModel)

	-- proximity prompts
	local driverSeat: VehicleSeat = vehicleInfo.DriverSeat
	local passengerSeats: { Seat } = VehicleUtil.findVehiclePassengerSeats(vehicleInfo.VehicleModel)

	-- driver prompt
	local driverPrompt: ProximityPrompt = VehicleSystemConfig.BasePrompt:Clone()
	driverPrompt.ObjectText = info.VehicleModel.Name
	driverPrompt.ActionText = "Drive"
	driverPrompt.RequiresLineOfSight = false
	driverPrompt.HoldDuration = info.VehicleConfig.SeatConfig.DriverPromptHoldDuration
	driverPrompt.MaxActivationDistance = info.VehicleConfig.SeatConfig.PassengerPromptDistance
	driverPrompt.Triggered:Connect(function(player: Player)
		module.DriverPromptTriggered(player, info, driverPrompt)
	end)
	driverPrompt.Parent = driverSeat

	-- passenger prompts
	for _, seat: Seat in ipairs(passengerSeats) do
		local passengerPrompt: ProximityPrompt = VehicleSystemConfig.BasePrompt:Clone()
		passengerPrompt.ObjectText = (seat:GetAttribute("SeatName") :: string?) or info.VehicleModel.Name
		passengerPrompt.ActionText = "Sit"
		passengerPrompt.KeyboardKeyCode = Enum.KeyCode.Q
		passengerPrompt.RequiresLineOfSight = false
		passengerPrompt.HoldDuration = info.VehicleConfig.SeatConfig.PassengerPromptHoldDuration
		passengerPrompt.MaxActivationDistance = info.VehicleConfig.SeatConfig.PassengerPromptDistance
		passengerPrompt.Triggered:Connect(function(player: Player)
			module.PassengerPromptTriggered(player, info, passengerPrompt, seat)
		end)
		passengerPrompt.Parent = seat
	end

	-- put all the sounds
	local function putSound(name: string, sound: Sound?, parent: Instance)
		if not sound then return end
		local clone = sound:Clone()
		clone.Name = name
		clone.Parent = parent
	end

	local soundConfig = config.DecorConfig.SoundsConfig
	putSound("Enter", soundConfig.Enter, vehicleInfo.DriverSeat)
	putSound("Dismount", soundConfig.Dismount, vehicleInfo.DriverSeat)
	putSound("EngineIdle", soundConfig.EngineIdle, vehicleInfo.EnginePart)
	putSound("EngineMove", soundConfig.EngineMove, vehicleInfo.EnginePart)

	info.DriverSeat.HeadsUpDisplay = false
	return info
end

function module.findWheels(vehicleModel: Model): { BasePart }
	local wheels = {} :: { BasePart }
	for _, wheel: Instance in ipairs(vehicleModel:GetDescendants()) do
		if wheel:IsA("BasePart") and wheel:HasTag("Wheel") then table.insert(wheels, wheel :: BasePart) end
	end
	return wheels
end

return module
