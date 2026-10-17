-- IMPORTS
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- VehicleSystemConfig scans global CollectionService state on require. These
-- functions only need its tag and attribute names, so use a local config stub.
JestGlobals.jest.mock(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig, function()
	return {
		Tag = "VehicleControl",
		PassengerSeatTag = "PassengerSeat",
		TeamAttribute = "VehicleTeam",
	}
end)
JestGlobals.jest.mock(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleConfigUtil, function()
	return {
		getConfig = function()
			return nil
		end,
	}
end)

local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.DestructibleObjectConfig)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("VehicleUtil", function()
	it("validates vehicles with both required tags", function()
		local vehicle = Instance.new("Model")
		CollectionService:AddTag(vehicle, "VehicleControl")
		CollectionService:AddTag(vehicle, DestructibleObjectConfig.Tag)

		expect(VehicleUtil.validateVehicle(vehicle)).toBe(true)

		vehicle:Destroy()
	end)

	it("rejects vehicles without the destructible object tag", function()
		local vehicle = Instance.new("Model")
		CollectionService:AddTag(vehicle, "VehicleControl")

		expect(VehicleUtil.validateVehicle(vehicle)).toBe(false)

		vehicle:Destroy()
	end)

	it("validates passenger seats by tag", function()
		local seat = Instance.new("Seat")
		CollectionService:AddTag(seat, "PassengerSeat")

		expect(VehicleUtil.validatePassengerSeat(seat)).toBe(true)

		seat:Destroy()
	end)

	it("compares the vehicle team attribute with a team's name", function()
		local vehicle = Instance.new("Model")
		vehicle:SetAttribute("VehicleTeam", "Blue")
		local team = { Name = "Blue" } :: any

		expect(VehicleUtil.isVehicleFriendly(vehicle, team)).toBe(true)

		team.Name = "Red"
		expect(VehicleUtil.isVehicleFriendly(vehicle, team)).toBe(false)

		vehicle:Destroy()
	end)
end)
