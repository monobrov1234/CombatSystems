-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- VehicleRigUtil only needs the vehicle config type at runtime for this test.
JestGlobals.jest.mock(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleConfigUtil, function()
	return {}
end)

local VehicleRigUtil = require(ServerScriptService.CombatSystemsServer.VehicleSystem.VehicleService.RigService.VehicleRigUtil)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("VehicleRigUtil", function()
	it("creates an invisible non-collidable center of mass with configured density", function()
		local vehicleConfig = { PhysicalConfig = { Mass = 3 } } :: any

		local centerOfMass = VehicleRigUtil.createCenterOfMass(vehicleConfig, {})

		expect(centerOfMass.Name).toBe("CenterOfMass")
		expect(centerOfMass.Size).toEqual(Vector3.new(10, 10, 10))
		expect(centerOfMass.CanCollide).toBe(false)
		expect(centerOfMass.Transparency).toBe(1)
		assert(centerOfMass.CustomPhysicalProperties)
		expect(centerOfMass.CustomPhysicalProperties.Density).toBe(3)

		centerOfMass:Destroy()
	end)
end)
