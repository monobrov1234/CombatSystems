-- IMPORTS
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TurretConfigUtil loads the default turret config, which depends on assets that
-- are not part of the test place. These tests cover TurretUtil's tag and lookup
-- helpers, so replace that unrelated config dependency before requiring it.
JestGlobals.jest.mock(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretConfigUtil, function()
	return {
		getConfig = function()
			return nil
		end,
	}
end)

local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local TurretSystemConfig = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.TurretSystemConfig)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

describe("TurretUtil", function()
	local turretModel

	beforeEach(function()
		turretModel = Instance.new("Model")
	end)

	afterEach(function()
		turretModel:Destroy()
	end)

	it("recognizes a model with the turret tag", function()
		CollectionService:AddTag(turretModel, TurretSystemConfig.Tag)

		expect(TurretUtil.validateTurret(turretModel)).toBe(true)
	end)

	it("rejects a model without the turret tag", function()
		expect(TurretUtil.validateTurret(turretModel)).toBe(false)
	end)

	it("finds the named turret seat", function()
		local seat = Instance.new("Seat")
		seat.Name = "TurretSeat"
		seat.Parent = turretModel

		expect(TurretUtil.findTurretSeat(turretModel)).toBe(seat)
	end)

	it("returns no seat when the model does not contain one", function()
		expect(TurretUtil.findTurretSeat(turretModel)).toBe(nil)
	end)

	it("finds tagged turret models among descendants", function()
		local taggedTurret = Instance.new("Model")
		taggedTurret.Parent = turretModel
		CollectionService:AddTag(taggedTurret, TurretSystemConfig.Tag)

		local untaggedModel = Instance.new("Model")
		untaggedModel.Parent = turretModel

		local foundTurrets = TurretUtil.findDescendantTurrets(turretModel)

		expect(#foundTurrets).toBe(1)
		expect(foundTurrets[1]).toBe(taggedTurret)
	end)
end)
