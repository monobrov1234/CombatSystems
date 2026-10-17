-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleSpawnerConfigUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleSpawnerConfigUtil)
local VehicleSpawnerConfigPath = ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSpawnerConfig
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

describe("VehicleSpawnerConfigUtil", function()
	local spawner

	beforeEach(function()
		spawner = Instance.new("Part")
		spawner.Name = "TestSpawner"
		local configModule = VehicleSpawnerConfigPath.Config:Clone()
		configModule.Name = "Config"
		configModule.Parent = spawner
	end)

	afterEach(function()
		spawner:Destroy()
	end)

	it("inherits the template config and uses the spawner color", function()
		spawner.Color = Color3.fromRGB(20, 40, 60)

		local config = VehicleSpawnerConfigUtil.parseSpawnerConfig(spawner)

		expect(config.Delay).toBe(2)
		expect(config.MaxUseDistance).toBe(20)
		expect(config.EnabledColor).toEqual(spawner.Color)
	end)

	it("returns the cached config for the same spawner", function()
		local firstConfig = VehicleSpawnerConfigUtil.parseSpawnerConfig(spawner)
		local secondConfig = VehicleSpawnerConfigUtil.parseSpawnerConfig(spawner)

		expect(secondConfig).toBe(firstConfig)
	end)
end)
