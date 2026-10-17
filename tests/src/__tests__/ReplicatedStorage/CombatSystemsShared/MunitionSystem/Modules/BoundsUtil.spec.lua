-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BoundsUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.BoundsUtil)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

describe("BoundsUtil", function()
	describe("distanceToPartBounds", function()
		local part

		beforeEach(function()
			part = Instance.new("Part")
			part.Size = Vector3.new(4, 4, 4)
		end)

		afterEach(function()
			part:Destroy()
		end)

		it("returns zero for a point inside the part", function()
			expect(BoundsUtil.distanceToPartBounds(Vector3.new(1, 1, 1), part)).toBe(0)
		end)

		it("returns the distance from a point outside the part to its nearest face", function()
			expect(BoundsUtil.distanceToPartBounds(Vector3.new(5, 0, 0), part)).toBe(3)
		end)

		it("measures distance correctly for a rotated part", function()
			part.CFrame = CFrame.Angles(0, math.rad(90), 0)
			local point = part.CFrame:PointToWorldSpace(Vector3.new(5, 0, 0))

			expect(BoundsUtil.distanceToPartBounds(point, part)).toBe(3)
		end)
	end)
end)
