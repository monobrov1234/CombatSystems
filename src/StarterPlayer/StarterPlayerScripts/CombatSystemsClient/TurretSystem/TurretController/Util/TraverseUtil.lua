--!strict

local module = {}
local funcs = {}
module.__index = module

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)

-- FINALS
local DEFAULT_START_SPEED = 8
local DEFAULT_STOP_SPEED = 5
local DIR_EPS = 0.001

local START_HOLD_TIME = 0.06 -- seconds
local STOP_HOLD_TIME = 0.02 -- seconds

local DIR_CHANGE_HOLD_TIME = 0.06 -- seconds
local RESTART_COOLDOWN_TIME = 0.5 -- seconds

local DIR_CHANGE_MIN_TRAVEL = 12
local MIN_TRAVEL_BEFORE_RESTART = 12
local START_MIN_TRAVEL = 6

export type SelfObject = typeof(setmetatable({}, module)) & {
	-- FINALS
	turretInfo: TurretUtil.TurretInfo,
	startSpeed: number,
	stopSpeed: number,
	traverseStartSound: Sound?,
	traverseSound: Sound?,
	traverseEndSound: Sound?,

	-- STATE
	moving: boolean,
	lastYawDeg: number?,
	lastDir: number,
	startHold: number,
	stopHold: number,

	dirChangeHold: number,
	restartCooldown: number,
	candidateDir: number,
	candidateTravel: number,
	movingTravel: number,

	startCandidateDir: number,
	startTravel: number,
}

-- PUBLIC API
function module.new(
	turretInfo: TurretUtil.TurretInfo,
	startSpeed: number?,
	stopSpeed: number?,
	traverseStart: Sound?,
	traverse: Sound?,
	traverseEnd: Sound?
): SelfObject
	local self = setmetatable({}, module) :: SelfObject

	self.turretInfo = turretInfo
	self.startSpeed = startSpeed or DEFAULT_START_SPEED
	self.stopSpeed = stopSpeed or DEFAULT_STOP_SPEED
	self.traverseStartSound = traverseStart
	self.traverseSound = traverse
	self.traverseEndSound = traverseEnd

	self.moving = false
	self.lastYawDeg = nil
	self.lastDir = 0
	self.startHold = 0
	self.stopHold = 0

	self.dirChangeHold = 0
	self.restartCooldown = 0
	self.candidateDir = 0
	self.candidateTravel = 0
	self.movingTravel = 0

	self.startCandidateDir = 0
	self.startTravel = 0

	return self
end

function module:destroy()
	local me = self :: SelfObject
	if me.traverseStartSound then me.traverseStartSound:Stop() end
	if me.traverseSound then me.traverseSound:Stop() end
	if me.traverseEndSound then me.traverseEndSound:Stop() end
end

function module:update(deltaTime: number)
	local me = self :: SelfObject
	if deltaTime <= 0 then return end

	if me.restartCooldown > 0 then me.restartCooldown = math.max(0, me.restartCooldown - deltaTime) end

	local _, yawRad, _ = me.turretInfo.YawMotor.C0:ToOrientation()
	local yawDeg = math.deg(yawRad)

	if me.lastYawDeg == nil then
		me.lastYawDeg = yawDeg
		return
	end

	local dYaw = funcs.shortestDeltaDeg(me.lastYawDeg, yawDeg)
	local absYaw = math.abs(dYaw)
	if absYaw <= DIR_EPS then
		dYaw = 0
		absYaw = 0
	end

	local speed = absYaw / deltaTime

	local dir = 0
	if dYaw > 0 then
		dir = 1
	elseif dYaw < 0 then
		dir = -1
	end

	local isFast = speed >= me.startSpeed
	local isSlow = speed <= me.stopSpeed

	if not me.moving then
		me.stopHold = 0
		me.dirChangeHold = 0
		me.candidateDir = 0
		me.candidateTravel = 0
		me.movingTravel = 0

		if isFast and dir ~= 0 then
			if me.startCandidateDir ~= dir then
				me.startCandidateDir = dir
				me.startHold = 0
				me.startTravel = 0
			end

			me.startHold += deltaTime
			me.startTravel += absYaw

			if me.startHold >= START_HOLD_TIME and me.startTravel >= START_MIN_TRAVEL then
				me.startHold = 0
				me.startTravel = 0
				me.startCandidateDir = 0

				me.lastDir = dir
				funcs.startMoving(me)
			end
		else
			me.startHold = 0
			me.startTravel = 0
			me.startCandidateDir = 0
		end
	else
		me.startHold = 0
		me.startTravel = 0
		me.startCandidateDir = 0

		if isFast and dir ~= 0 then
			me.movingTravel += absYaw
		end

		local wantsDirChange = isFast and dir ~= 0 and me.lastDir ~= 0 and dir ~= me.lastDir

		if wantsDirChange then
			if me.candidateDir ~= dir then
				me.candidateDir = dir
				me.dirChangeHold = 0
				me.candidateTravel = 0
			end

			me.dirChangeHold += deltaTime
			me.candidateTravel += absYaw

			if
				me.dirChangeHold >= DIR_CHANGE_HOLD_TIME
				and me.restartCooldown <= 0
				and me.candidateTravel >= DIR_CHANGE_MIN_TRAVEL
				and me.movingTravel >= MIN_TRAVEL_BEFORE_RESTART
			then
				me.dirChangeHold = 0
				me.candidateDir = 0
				me.candidateTravel = 0
				me.movingTravel = 0

				me.lastDir = dir
				funcs.hardRestart(me)
				me.restartCooldown = RESTART_COOLDOWN_TIME
				me.stopHold = 0
			end
		else
			me.dirChangeHold = 0
			me.candidateDir = 0
			me.candidateTravel = 0

			if isSlow then
				me.stopHold += deltaTime
				if me.stopHold >= STOP_HOLD_TIME then
					me.stopHold = 0
					funcs.stopMoving(me)
				end
			else
				me.stopHold = 0
			end

			if isFast and dir ~= 0 then me.lastDir = dir end
		end
	end

	me.lastYawDeg = yawDeg
end

-- INTERNAL FUNCTIONS
function funcs.startMoving(self: SelfObject)
	self.moving = true
	self.movingTravel = 0

	if self.traverseEndSound then self.traverseEndSound:Stop() end

	if self.traverseStartSound then
		self.traverseStartSound:Stop()
		self.traverseStartSound:Play()
	end

	if self.traverseSound then
		if not self.traverseSound.IsPlaying then self.traverseSound:Play() end
	end
end

function funcs.stopMoving(self: SelfObject)
	self.moving = false
	self.dirChangeHold = 0
	self.candidateDir = 0
	self.candidateTravel = 0
	self.movingTravel = 0

	if self.traverseSound then self.traverseSound:Stop() end
	if self.traverseStartSound then self.traverseStartSound:Stop() end

	if self.traverseEndSound then
		self.traverseEndSound:Stop()
		self.traverseEndSound:Play()
	end
end

function funcs.hardRestart(self: SelfObject)
	if self.traverseSound then self.traverseSound:Stop() end
	if self.traverseStartSound then self.traverseStartSound:Stop() end
	if self.traverseEndSound then self.traverseEndSound:Stop() end

	self.moving = true
	self.movingTravel = 0

	if self.traverseStartSound then self.traverseStartSound:Play() end

	if self.traverseSound then self.traverseSound:Play() end
end

function funcs.normalize180(angleDeg: number): number
	angleDeg = (angleDeg + 180) % 360
	if angleDeg < 0 then
		angleDeg += 360
	end
	return angleDeg - 180
end

function funcs.shortestDeltaDeg(fromDeg: number, toDeg: number): number
	return funcs.normalize180(toDeg - fromDeg)
end

return module
