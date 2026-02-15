local module = {}
local funcs = {}
module.__index = module

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)

local DEFAULT_START_SPEED = 8 -- deg/sec
local DEFAULT_STOP_SPEED = 5 -- deg/sec
local DIR_EPS = 0.001

local START_HOLD_TIME = 0.06 -- seconds
local STOP_HOLD_TIME = 0.02 -- seconds

local DIR_CHANGE_HOLD_TIME = 0.06 -- seconds
local RESTART_COOLDOWN_TIME = 0.5 -- seconds

local DIR_CHANGE_MIN_TRAVEL = 12 -- degrees in new direction before restart is allowed
local MIN_TRAVEL_BEFORE_RESTART = 12 -- degrees in current movement before restart is allowed

local START_MIN_TRAVEL = 6 -- degrees in one direction before any sounds can start

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

function module.new(
	turretInfo: TurretUtil.TurretInfo,
	startSpeed: number?,
	stopSpeed: number?,
	traverseStart: Sound?,
	traverse: Sound?,
	traverseEnd: Sound?
): SelfObject
	local self: SelfObject = setmetatable({}, module)

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
	local self: SelfObject = self
	if self.traverseStartSound then self.traverseStartSound:Stop() end
	if self.traverseSound then self.traverseSound:Stop() end
	if self.traverseEndSound then self.traverseEndSound:Stop() end
end

function module:update(deltaTime: number)
	local self: SelfObject = self
	if deltaTime <= 0 then return end

	if self.restartCooldown > 0 then self.restartCooldown = math.max(0, self.restartCooldown - deltaTime) end

	local _, yawRad, _ = self.turretInfo.YawMotor.C0:ToOrientation()
	local yawDeg = math.deg(yawRad)

	if self.lastYawDeg == nil then
		self.lastYawDeg = yawDeg
		return
	end

	local dYaw = funcs.shortestDeltaDeg(self.lastYawDeg, yawDeg)
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

	local isFast = speed >= self.startSpeed
	local isSlow = speed <= self.stopSpeed

	if not self.moving then
		self.stopHold = 0
		self.dirChangeHold = 0
		self.candidateDir = 0
		self.candidateTravel = 0
		self.movingTravel = 0

		if isFast and dir ~= 0 then
			if self.startCandidateDir ~= dir then
				self.startCandidateDir = dir
				self.startHold = 0
				self.startTravel = 0
			end

			self.startHold += deltaTime
			self.startTravel += absYaw

			if self.startHold >= START_HOLD_TIME and self.startTravel >= START_MIN_TRAVEL then
				self.startHold = 0
				self.startTravel = 0
				self.startCandidateDir = 0

				self.lastDir = dir
				funcs.startMoving(self)
			end
		else
			self.startHold = 0
			self.startTravel = 0
			self.startCandidateDir = 0
		end
	else
		self.startHold = 0
		self.startTravel = 0
		self.startCandidateDir = 0

		if isFast and dir ~= 0 then
			self.movingTravel += absYaw
		end

		local wantsDirChange = isFast and dir ~= 0 and self.lastDir ~= 0 and dir ~= self.lastDir

		if wantsDirChange then
			if self.candidateDir ~= dir then
				self.candidateDir = dir
				self.dirChangeHold = 0
				self.candidateTravel = 0
			end

			self.dirChangeHold += deltaTime
			self.candidateTravel += absYaw

			if
				self.dirChangeHold >= DIR_CHANGE_HOLD_TIME
				and self.restartCooldown <= 0
				and self.candidateTravel >= DIR_CHANGE_MIN_TRAVEL
				and self.movingTravel >= MIN_TRAVEL_BEFORE_RESTART
			then
				self.dirChangeHold = 0
				self.candidateDir = 0
				self.candidateTravel = 0
				self.movingTravel = 0

				self.lastDir = dir
				funcs.hardRestart(self)
				self.restartCooldown = RESTART_COOLDOWN_TIME
				self.stopHold = 0
			end
		else
			self.dirChangeHold = 0
			self.candidateDir = 0
			self.candidateTravel = 0

			if isSlow then
				self.stopHold += deltaTime
				if self.stopHold >= STOP_HOLD_TIME then
					self.stopHold = 0
					funcs.stopMoving(self)
				end
			else
				self.stopHold = 0
			end

			if isFast and dir ~= 0 then self.lastDir = dir end
		end
	end

	self.lastYawDeg = yawDeg
end

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
