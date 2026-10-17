-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("Signal", function()
	it("fires connected callbacks with the provided arguments", function()
		local signal = Signal.new()
		local receivedArguments = nil

		signal:connect(function(firstArgument, secondArgument)
			receivedArguments = { firstArgument, secondArgument }
		end)

		signal:fire("shot", 3)

		expect(receivedArguments).toEqual({ "shot", 3 })
	end)

	it("fires callbacks from highest to lowest priority", function()
		local signal = Signal.new()
		local callOrder = {}

		signal:connect(function()
			table.insert(callOrder, "normal")
		end, Signal.Priority.NORMAL)
		signal:connect(function()
			table.insert(callOrder, "high")
		end, Signal.Priority.HIGH)

		signal:fire()

		expect(callOrder).toEqual({ "high", "normal" })
	end)

	it("stops firing when a callback returns true", function()
		local signal = Signal.new()
		local lowerPriorityCallbackCalled = false

		signal:connect(function()
			return true
		end, Signal.Priority.HIGH)
		signal:connect(function()
			lowerPriorityCallbackCalled = true
		end, Signal.Priority.NORMAL)

		signal:fire()

		expect(lowerPriorityCallbackCalled).toBe(false)
	end)

	it("continues safely when a callback disconnects itself", function()
		local signal = Signal.new()
		local laterCallbackCalled = false
		local connection

		connection = signal:connect(function()
			connection:disconnect()
		end, Signal.Priority.HIGH)
		signal:connect(function()
			laterCallbackCalled = true
		end, Signal.Priority.NORMAL)

		signal:fire()

		expect(laterCallbackCalled).toBe(true)
	end)

	it("does not fire connections after destroy", function()
		local signal = Signal.new()
		local callbackCalled = false

		signal:connect(function()
			callbackCalled = true
		end)
		signal:destroy()
		signal:fire()

		expect(callbackCalled).toBe(false)
	end)
end)
