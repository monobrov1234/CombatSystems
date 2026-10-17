-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TraverseUtil uses TurretUtil only for a type, so avoid loading turret configs.
JestGlobals.jest.mock(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil, function()
	return {}
end)

local TraverseUtil = require(
	StarterPlayer.StarterPlayerScripts.CombatSystemsClient.TurretSystem.TurretController.Util.TraverseUtil
)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

local function makeSoundMock()
	local sound = { IsPlaying = false, playCount = 0, stopCount = 0 }
	function sound:Play()
		self.playCount += 1
		self.IsPlaying = true
	end
	function sound:Stop()
		self.stopCount += 1
		self.IsPlaying = false
	end
	return sound
end

describe("TraverseUtil", function()
	it("starts and stops traverse sounds after sustained turret movement", function()
		local startSound = makeSoundMock()
		local loopSound = makeSoundMock()
		local endSound = makeSoundMock()
		local turretInfo = { YawMotor = { C0 = CFrame.identity } } :: any
		local traverse = TraverseUtil.new(turretInfo, 8, 5, startSound, loopSound, endSound)

		traverse:update(0.05)
		turretInfo.YawMotor.C0 = CFrame.Angles(0, math.rad(10), 0)
		traverse:update(0.06)

		expect(traverse.moving).toBe(true)
		expect(startSound.playCount).toBe(1)
		expect(loopSound.playCount).toBe(1)

		traverse:update(0.02)

		expect(traverse.moving).toBe(false)
		expect(loopSound.IsPlaying).toBe(false)
		expect(endSound.playCount).toBe(1)
	end)

	it("ignores non-positive update durations", function()
		local turretInfo = { YawMotor = { C0 = CFrame.identity } } :: any
		local traverse = TraverseUtil.new(turretInfo)

		traverse:update(0)

		expect(traverse.lastYawDeg).toBe(nil)
		expect(traverse.moving).toBe(false)
	end)
end)
