--!strict

local module = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleConfigUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleConfigUtilModule)
local RigUtil = require(ServerScriptService.CombatSystemsServer.Utils.RigUtilModule)

function module.createCenterOfMass(vehicleConfig: VehicleConfigUtil.DefaultType, baseParts: { BasePart }): Part
	local centerOfMass = Instance.new("Part")
	centerOfMass.Name = "CenterOfMass"
	centerOfMass.Size = Vector3.new(10, 10, 10)
	centerOfMass.CanCollide = false
	centerOfMass.Transparency = 1
	centerOfMass.CustomPhysicalProperties = PhysicalProperties.new(vehicleConfig.PhysicalConfig.Mass, 0, 0, 0, 0)
	return centerOfMass
end

function module.constraintWheel(vehicleConfig: VehicleConfigUtil.DefaultType, chassis: BasePart, totalMass: number, wheelCount: number, wheel: BasePart)
	-- weld wheel children together and set collision group
	for _, descendant: Instance in ipairs(wheel:GetDescendants()) do
		if not descendant:isA("BasePart") then continue end
		RigUtil.weld(descendant, wheel)
		descendant.CollisionGroup = "Wheel"
	end
	wheel.CollisionGroup = "Wheel"

	-- then constraint
	local rootAttachment = Instance.new("Attachment")
	rootAttachment.CFrame = chassis.CFrame:ToObjectSpace(wheel.CFrame * CFrame.Angles(0, 0, math.rad(-90)))
	rootAttachment.Parent = chassis

	local wheelAttachment = Instance.new("Attachment")
	wheelAttachment.Parent = wheel

	local spring = Instance.new("SpringConstraint")
	spring.Name = "SuspensionSpring"
	spring.Attachment0 = rootAttachment
	spring.Attachment1 = wheelAttachment
	spring.FreeLength = vehicleConfig.SuspensionConfig.FreeLength
	spring.Stiffness = (totalMass / wheelCount) * vehicleConfig.SuspensionConfig.StiffnessMultiplier
	spring.Damping = (spring.Stiffness / 100) * vehicleConfig.SuspensionConfig.DampingPercent
	spring.Parent = wheel

	local motor = Instance.new("CylindricalConstraint")
	motor.Name = "WheelMotor"
	motor.Attachment0 = rootAttachment
	motor.Attachment1 = wheelAttachment
	motor.InclinationAngle = 90
	motor.AngularActuatorType = Enum.ActuatorType.Motor
	motor.MotorMaxTorque = (vehicleConfig.MovementConfig.TorqueMultiplier * totalMass / wheelCount) * (wheel.Size.Y / 2)
	motor.LimitsEnabled = true
	motor.UpperLimit = 0.2 -- wheel sticking fix
	motor.LowerLimit = vehicleConfig.SuspensionConfig.FreeLength + vehicleConfig.SuspensionConfig.LowerLimit
	motor.Parent = wheel

	return rootAttachment, wheelAttachment, spring, motor
end

return module
