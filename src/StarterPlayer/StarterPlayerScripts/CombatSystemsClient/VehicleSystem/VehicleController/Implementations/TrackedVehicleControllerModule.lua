--[[
    Tracked Vehicle Controller (Client-Side Only)

    This controller is designed for tracked vehicles with two parallel tracks and no wheels.
]]

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)

-- STATE
local vehicleInfo: VehicleUtil.VehicleInfo
local wheelMotorsRight: { CylindricalConstraint } = {}
local wheelMotorsLeft: { CylindricalConstraint } = {}
local maxAngularVelocity: number
local throttleForward = 0

function module.handleSeated(info: VehicleUtil.VehicleInfo)
	vehicleInfo = info

	local wheelDiameter: number
	for _, part: Instance in ipairs(vehicleInfo.VehicleModel:GetDescendants()) do
		if part:HasTag("Wheel") then
			local motor = part:FindFirstChild("WheelMotor")
			assert(motor, "WheelMotor not found in wheel part")
			assert(motor:IsA("CylindricalConstraint"), "Found WheelMotor is not CylindricalConstraint")
			local side = part:GetAttribute("TrackSide")
			assert(side, "Wheel lacks TrackSide attribute")

			if side == "R" then
				table.insert(wheelMotorsRight, motor)
			elseif side == "L" then
				table.insert(wheelMotorsLeft, motor)
			end

			if not wheelDiameter then wheelDiameter = part.Size.Y end
		end
	end

	maxAngularVelocity = vehicleInfo.VehicleConfig.MovementConfig.MaxSpeed / (wheelDiameter / 2)
end

function module.handleDismount()
	vehicleInfo = nil
	for _, motor in ipairs(wheelMotorsRight) do
		motor.AngularVelocity = 0
	end
	for _, motor in ipairs(wheelMotorsLeft) do
		motor.AngularVelocity = 0
	end
	table.clear(wheelMotorsRight)
	table.clear(wheelMotorsLeft)
	maxAngularVelocity = nil
	throttleForward = 0
end

function module.driveLoop(deltaTime: number)
	local vehicleSeat = vehicleInfo.DriverSeat
	local vehicleConfig = vehicleInfo.VehicleConfig

	local throttle = -vehicleSeat.ThrottleFloat
	local steer = vehicleSeat.SteerFloat

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
		current = expApproachToZero(current, reverseStopTime * 0.5)

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

	if current == 0 and steer == 0 then
		for _, motor in ipairs(wheelMotorsRight) do
			motor.AngularVelocity = 0
		end
		for _, motor in ipairs(wheelMotorsLeft) do
			motor.AngularVelocity = 0
		end
		return
	end

	local forwardComponent = current * maxAngularVelocity

	local turnComponent = 0
	if steer ~= 0 then turnComponent = math.sign(steer) * (maxAngularVelocity / vehicleConfig.MovementConfigTracked.TurnRate) end

	local rightAngularVelocity = forwardComponent + turnComponent
	local leftAngularVelocity = forwardComponent - turnComponent

	for _, motor in ipairs(wheelMotorsRight) do
		motor.AngularVelocity = rightAngularVelocity
	end
	for _, motor in ipairs(wheelMotorsLeft) do
		motor.AngularVelocity = leftAngularVelocity
	end
end

return module
