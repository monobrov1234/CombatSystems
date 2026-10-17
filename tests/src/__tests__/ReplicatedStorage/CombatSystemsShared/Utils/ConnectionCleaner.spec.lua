-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("ConnectionCleaner", function()
	it("disconnects and removes a registered signal connection", function()
		local signal = Signal.new()
		local cleaner = ConnectionCleaner.new()
		local callCount = 0
		local connection = cleaner:add(signal:connect(function()
			callCount += 1
		end))

		cleaner:disconnect(connection)
		signal:fire()

		expect(callCount).toBe(0)
		expect(#cleaner.connections).toBe(0)
	end)

	it("disconnects all registered signal connections", function()
		local signal = Signal.new()
		local cleaner = ConnectionCleaner.new()
		local callCount = 0

		cleaner:add(signal:connect(function()
			callCount += 1
		end))
		cleaner:add(signal:connect(function()
			callCount += 1
		end))

		cleaner:disconnectAll()
		signal:fire()

		expect(callCount).toBe(0)
		expect(#cleaner.connections).toBe(0)
	end)

	it("returns the connection added to the cleaner", function()
		local cleaner = ConnectionCleaner.new()
		local signal = Signal.new()
		local connection = signal:connect(function() end)

		expect(cleaner:add(connection)).toBe(connection)
	end)
end)
