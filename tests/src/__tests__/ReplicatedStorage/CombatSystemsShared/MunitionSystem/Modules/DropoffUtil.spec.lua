-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropoffUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.DropoffUtil)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("DropoffUtil", function()
	describe("calculateDropoff", function()
		it("keeps full damage before the dropoff distance", function()
			expect(DropoffUtil.calculateDropoff(100, 10, 20, 100)).toBe(100)
		end)

		it("reduces damage linearly between the dropoff distance and maximum distance", function()
			expect(DropoffUtil.calculateDropoff(100, 60, 20, 100)).toBe(50)
		end)

		it("returns zero at and beyond the maximum distance", function()
			expect(DropoffUtil.calculateDropoff(100, 100, 20, 100)).toBe(0)
			expect(DropoffUtil.calculateDropoff(100, 120, 20, 100)).toBe(0)
		end)
	end)

	describe("calculateExplosionDropoff", function()
		it("keeps full damage inside the start radius", function()
			expect(DropoffUtil.calculateExplosionDropoff(80, 10, 20, 100)).toBe(80)
		end)

		it("returns zero outside the explosion radius", function()
			expect(DropoffUtil.calculateExplosionDropoff(80, 101, 20, 100)).toBe(0)
		end)
	end)
end)
