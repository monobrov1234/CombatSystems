-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Connection = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal.Connection)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("Connection", function()
	it("returns the callback and priority passed to its constructor", function()
		local callback = function() end
		local connection = Connection.new(callback, 25, function() end)

		expect(connection:getCallback()).toBe(callback)
		expect(connection:getPriority()).toBe(25)
	end)

	it("runs its disconnect callback only once", function()
		local disconnectCallCount = 0
		local connection = Connection.new(function() end, 50, function()
			disconnectCallCount += 1
		end)

		connection:disconnect()
		connection:disconnect()

		expect(disconnectCallCount).toBe(1)
	end)
end)
