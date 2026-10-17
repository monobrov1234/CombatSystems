-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("MunitionConfigUtil", function()
	it("returns the default munition config", function()
		local config = MunitionConfigUtil.getDefaultConfig()

		expect(config.MaxDistance).toBe(1500)
		expect(config.HeadshotMultiplier).toBe(1.5)
		expect(config.EnableDropoff).toBe(false)
	end)

	it("returns no config for an unknown munition", function()
		expect(MunitionConfigUtil.getConfig("UnknownMunition")).toBe(nil)
	end)
end)
