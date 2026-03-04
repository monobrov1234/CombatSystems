--!strict

local module = {}
local funcs = {}
module.__index = module

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)

-- FINALS
local deadZone = 0.01

export type SelfObject = typeof(setmetatable({}, module)) & {
	-- FINALS
	turretInfo: TurretUtil.TurretInfo,

	-- STATE
	currentYawC0: CFrame,
	currentPitchC0: CFrame,
}

-- PUBLIC API
function module.new(turretInfo: TurretUtil.TurretInfo): SelfObject
	local self = setmetatable({}, module) :: SelfObject
	self.turretInfo = turretInfo
	self.currentYawC0 = turretInfo.YawMotor.C0
	self.currentPitchC0 = turretInfo.PitchMotor.C0
	return self
end

function module:rotateTurret(goal: Vector3, deltaTime: number)
	local me = self :: SelfObject

	local yawMotor = me.turretInfo.YawMotor
	local pitchMotor = me.turretInfo.PitchMotor
	local limitsConfig = me.turretInfo.TurretConfig.LimitsConfig
	local yawPart0 = yawMotor.Part0
	local pitchPart0 = pitchMotor.Part0
	if not yawPart0 or not pitchPart0 then return end

	-- YAW
	do
		local baseCFrame = yawPart0.CFrame
		local dirVecWorld = goal - baseCFrame.Position
		local dirVecLocal = baseCFrame:VectorToObjectSpace(dirVecWorld)
		local dirVecLocal2D = Vector3.new(dirVecLocal.X, 0, dirVecLocal.Z)
		if dirVecLocal2D.Magnitude > deadZone then
			local worldYawDeg = -math.deg(math.atan2(dirVecLocal2D.X, -dirVecLocal2D.Z))
			local clampedMotorYawDeg = worldYawDeg

			local fullCircle = math.abs(limitsConfig.YawLeftLimit) == 180 and math.abs(limitsConfig.YawRightLimit) == 180
			if not fullCircle then -- ignore if limits full range
				clampedMotorYawDeg = funcs.clampAroundCenter(worldYawDeg, -limitsConfig.YawCenter, limitsConfig.YawLeftLimit, limitsConfig.YawRightLimit)
			end

			local x, y, z = me.currentYawC0:ToOrientation()
			local currentMotorYawDeg = math.deg(y)
			local newMotorYawDeg = funcs.stepAngle(
				currentMotorYawDeg,
				clampedMotorYawDeg,
				limitsConfig.YawSpeed,
				-limitsConfig.YawCenter,
				limitsConfig.YawLeftLimit,
				limitsConfig.YawRightLimit,
				fullCircle,
				deltaTime
			)

			me.currentYawC0 = CFrame.fromOrientation(x, math.rad(newMotorYawDeg), z) + yawMotor.C0.Position
		end
	end

	-- PITCH
	do
		local baseCFrame = pitchPart0.CFrame
		local dirWorld = goal - baseCFrame.Position
		local dirLocal = baseCFrame:VectorToObjectSpace(dirWorld)
		local horizLen = math.sqrt((dirLocal.X * dirLocal.X) + (dirLocal.Z * dirLocal.Z))
		if horizLen > deadZone then
			local worldPitchDeg = math.deg(math.atan2(dirLocal.Y, horizLen))
			local clampedMotorPitchDeg = worldPitchDeg

			local fullCircle = math.abs(limitsConfig.PitchDownLimit) == 180 and math.abs(limitsConfig.PitchUpLimit) == 180
			if not fullCircle then -- ignore if limits full range (this should not happen for pitch)
				clampedMotorPitchDeg = funcs.clampAroundCenter(worldPitchDeg, limitsConfig.PitchCenter, limitsConfig.PitchDownLimit, limitsConfig.PitchUpLimit)
			end

			local x, y, z = me.currentPitchC0:ToOrientation()
			local currentMotorPitchDeg = math.deg(x)
			local newMotorPitchDeg = funcs.stepAngle(
				currentMotorPitchDeg,
				clampedMotorPitchDeg,
				limitsConfig.PitchSpeed,
				limitsConfig.PitchCenter,
				limitsConfig.PitchDownLimit,
				limitsConfig.PitchUpLimit,
				fullCircle,
				deltaTime
			)

			me.currentPitchC0 = CFrame.fromOrientation(math.rad(newMotorPitchDeg), y, z) + pitchMotor.C0.Position
		end

		yawMotor.C0 = me.currentYawC0
		pitchMotor.C0 = me.currentPitchC0
	end
end

-- INTERNAL FUNCTIONS
function funcs.stepAngle(
	currentDeg: number,
	targetDeg: number,
	speedDegPerSec: number,
	centerDeg: number,
	minOffsetDeg: number,
	maxOffsetDeg: number,
	fullCircle: boolean,
	deltaTime: number
): number
	if speedDegPerSec <= 0 or deltaTime <= 0 then return currentDeg end

	local maxStep = speedDegPerSec * deltaTime
	if fullCircle then -- full 360
		currentDeg = funcs.normalize180(currentDeg)
		targetDeg = funcs.normalize180(targetDeg)

		local diff = funcs.shortestDeltaDeg(currentDeg, targetDeg)
		if math.abs(diff) <= maxStep then return targetDeg end

		if diff > 0 then
			return funcs.normalize180(currentDeg + maxStep)
		else
			return funcs.normalize180(currentDeg - maxStep)
		end
	end

	-- limited arc around center
	local curRel = funcs.normalize180(currentDeg - centerDeg)
	local tgtRel = funcs.normalize180(targetDeg - centerDeg)
	curRel = math.clamp(curRel, -minOffsetDeg, maxOffsetDeg)
	tgtRel = math.clamp(tgtRel, -minOffsetDeg, maxOffsetDeg)

	local diff = tgtRel - curRel
	if math.abs(diff) <= maxStep then return funcs.normalize180(centerDeg + tgtRel) end

	if diff > 0 then
		curRel += maxStep
	else
		curRel -= maxStep
	end

	return funcs.normalize180(centerDeg + curRel)
end

function funcs.clampAroundCenter(angleDeg: number, centerDeg: number, minOffsetDeg: number, maxOffsetDeg: number): number
	angleDeg = funcs.normalize180(angleDeg)
	centerDeg = funcs.normalize180(centerDeg)
	local rel = funcs.normalize180(angleDeg - centerDeg)
	local relClamped = math.clamp(rel, -minOffsetDeg, maxOffsetDeg)
	return funcs.normalize180(centerDeg + relClamped)
end

function funcs.shortestDeltaDeg(currentDeg: number, targetDeg: number): number
	return funcs.normalize180(targetDeg - currentDeg)
end

function funcs.normalize180(angleDeg: number): number
	angleDeg = (angleDeg + 180) % 360
	if angleDeg < 0 then
		angleDeg += 360
	end
	return angleDeg - 180
end

return module
