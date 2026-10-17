-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.SoundUtil)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("SoundUtil", function()
	it("plays a sound with the requested name", function()
		local playCallCount = 0
		local sound = {
			IsA = function(_, className)
				return className == "Sound"
			end,
			Play = function()
				playCallCount += 1
			end,
		}
		local soundParent = {
			FindFirstChild = function(_, soundName)
				if soundName == "Fire" then
					return sound
				end
				return nil
			end,
		} :: any

		SoundUtil.play("Fire", soundParent)

		expect(playCallCount).toBe(1)
	end)

	it("does nothing when the named child is not a sound", function()
		local playCallCount = 0
		local child = {
			IsA = function()
				return false
			end,
			Play = function()
				playCallCount += 1
			end,
		}
		local soundParent = {
			FindFirstChild = function()
				return child
			end,
		} :: any

		SoundUtil.play("Fire", soundParent)

		expect(playCallCount).toBe(0)
	end)
end)
