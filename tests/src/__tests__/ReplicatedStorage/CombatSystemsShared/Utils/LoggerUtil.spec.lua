-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local afterEach = JestGlobals.afterEach

describe("LoggerUtil", function()
	afterEach(function()
		JestGlobals.jest.restoreAllMocks()
	end)

	it("formats placeholders and writes an info message", function()
		local printSpy = JestGlobals.jest.spyOn(JestGlobals.jest.globalEnv, "print")
		local logger = Logger.new("Test")

		logger:info("health={:.2f} name={}", 12.345, "Tank")

		expect(printSpy).toHaveBeenCalledWith("[INFO] [Test] health=12.35 name=Tank")
	end)

	it("falls back to the value when a format specifier is invalid", function()
		local printSpy = JestGlobals.jest.spyOn(JestGlobals.jest.globalEnv, "print")
		local logger = Logger.new("Test")

		logger:info("value={:invalid}", "text")

		expect(printSpy).toHaveBeenCalledWith("[INFO] [Test] value=text")
	end)
end)
