--[[
    Normal Vehicle Controller (Client-Side Only)
    @Monobrov1234

    This controller is designed for standard wheeled vehicles that steer using two
    front turnable wheels and support any number of non-steering rear wheels.
]]

local funcs = {}
local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)

-- STATE
local vehicleInfo: VehicleUtil.VehicleInfo
local wheelMotors: { CylindricalConstraint } = {}
local leftSteerAttachments: { Attachment } = {}
local rightSteerAttachments: { Attachment } = {}
local initialSteerY: number
local maxAngularVelocity: number
local throttleForward = 0

function module.handleSeated(info: VehicleUtil.VehicleInfo)
	vehicleInfo = info

	local wheelDiameter: number
	for _, descendant: Instance in ipairs(vehicleInfo.VehicleModel:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:HasTag("Wheel") then
			local motor = descendant:FindFirstChild("WheelMotor") :: CylindricalConstraint?
			assert(motor and motor:IsA("CylindricalConstraint"), "Wheel has no WheelMotor constraint")
			table.insert(wheelMotors, motor)

			if not wheelDiameter then wheelDiameter = descendant.Size.Y end
		end
	end

	local chassis: BasePart = vehicleInfo.VehicleModel.PrimaryPart
	assert(chassis, "Vehicle has no primary part (chassis)")
	for _, child: Instance in ipairs(chassis:GetChildren()) do
		if child:IsA("Attachment") and child.Name ~= "Attachment" then
			table.insert(child.Name == "AttachmentSL" and leftSteerAttachments or rightSteerAttachments, child)
		end
	end

	assert(#leftSteerAttachments > 0, "Vehicle has no left steering attachments")
	assert(#rightSteerAttachments > 0, "Vehicle has no right steering attachments")
	initialSteerY = leftSteerAttachments[1].Orientation.Y
	maxAngularVelocity = vehicleInfo.VehicleConfig.MovementConfig.MaxSpeed / (wheelDiameter / 2)
end

function module.handleDismount()
	vehicleInfo = nil
	maxAngularVelocity = nil
	throttleForward = 0

	for _, motor in ipairs(wheelMotors) do
		motor.AngularVelocity = 0
	end
	table.clear(wheelMotors)

	local defaultOrientation: Vector3 = Vector3.new(1, 0, 1) -- preserve X and Z coordinates, erase Y
	for _, attachment: Attachment in ipairs(leftSteerAttachments) do
		attachment.Orientation *= defaultOrientation
		attachment.Orientation += Vector3.new(0, initialSteerY, 0)
	end
	table.clear(leftSteerAttachments)
	for _, attachment: Attachment in ipairs(rightSteerAttachments) do
		attachment.Orientation *= defaultOrientation
		attachment.Orientation += Vector3.new(0, initialSteerY, 0)
	end
	table.clear(rightSteerAttachments)
end

function module.driveLoop(deltaTime: number)
	local vehicleSeat = vehicleInfo.DriverSeat
	local vehicleConfig = vehicleInfo.VehicleConfig
	local someAttachment: Attachment = leftSteerAttachments[1]
	assert(someAttachment)

	local orientation: Vector3 = Vector3.new(
		someAttachment.Orientation.X,
		initialSteerY + (-math.sign(vehicleSeat.SteerFloat) * vehicleConfig.MovementConfigNormal.WheelTurnAngle),
		someAttachment.Orientation.Z
	)
	for _, attachment: Attachment in ipairs(leftSteerAttachments) do
		attachment.Orientation = orientation
	end
	for _, attachment: Attachment in ipairs(rightSteerAttachments) do
		attachment.Orientation = orientation
	end

	local throttle = -vehicleSeat.ThrottleFloat

	local current = throttleForward
	local desired = math.clamp(throttle, -1, 0.5)

	local brake01 = math.clamp(vehicleConfig.MovementConfig.Braking, 0, 1)
	local accelRate = vehicleConfig.MovementConfig.Acceleration

	local stopTime = 1.2 - 1.1 * brake01 -- 1.2s .. 0.1s
	local reverseStopTime = stopTime * 0.55

	local function expApproachToZero(x: number, timeConst: number): number
		local k = math.exp(-deltaTime / math.max(timeConst, 0.02))
		return x * k
	end

	if desired == 0 then
		current = expApproachToZero(current, stopTime)
	elseif current ~= 0 and math.sign(desired) ~= math.sign(current) then
		current = expApproachToZero(current, reverseStopTime * 0.5) -- 2x faster brake if reverse in opposite direction

		if math.abs(current) < 0.03 then current = 0 end
	else
		local maxDelta = accelRate * deltaTime
		local d = desired - current
		if d > maxDelta then
			current += maxDelta
		elseif d < -maxDelta then
			current -= maxDelta
		else
			current = desired
		end
	end

	-- deadzone
	if throttle == 0 and math.abs(current) < 0.05 then current = 0 end

	current = math.clamp(current, -1, 0.5)
	throttleForward = current

	for _, motor: CylindricalConstraint in ipairs(wheelMotors) do
		motor.AngularVelocity = current * maxAngularVelocity
	end
end

return module
