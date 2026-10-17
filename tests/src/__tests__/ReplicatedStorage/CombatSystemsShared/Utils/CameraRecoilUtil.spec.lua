-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraRecoil = require(ReplicatedStorage.CombatSystemsShared.Utils.CameraRecoilUtil)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

describe("CameraRecoilUtil", function()
	local recoil

	beforeEach(function()
		recoil = CameraRecoil.new()
	end)

	it("applies an instant kick in radians", function()
		recoil:Kick(90, -45, 0)

		expect(recoil.offset).toEqual(Vector3.new(math.pi / 2, -math.pi / 4, 0))
	end)

	it("scales instant kicks by strength", function()
		recoil:Kick(30, 0, 0, 2)

		expect(math.abs(recoil.offset.X - math.rad(60)) < 1e-6).toBe(true)
	end)

	it("queues timed kicks without immediately changing the offset", function()
		recoil:Kick(10, 20, 30, 2, 0.5)

		expect(recoil.offset).toEqual(Vector3.new())
		expect(#recoil.kicks).toBe(1)
		expect(recoil.kicks[1].duration).toBe(0.5)
		expect(recoil.kicks[1].delta).toEqual(Vector3.new(math.rad(20), math.rad(40), math.rad(60)))
	end)

	it("resets accumulated and queued recoil", function()
		recoil:Kick(15, 0, 0)
		recoil:Kick(5, 0, 0, 1, 0.2)
		recoil.applied = Vector3.new(1, 2, 3)

		recoil:Reset()

		expect(recoil.offset).toEqual(Vector3.new())
		expect(recoil.applied).toEqual(Vector3.new())
		expect(#recoil.kicks).toBe(0)
	end)
end)
