-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableInheritUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.TableInheritUtil)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("TableInheritUtil", function()
	describe("inheritConfig", function()
		it("uses the most specific config to override defaults", function()
			local result = TableInheritUtil.inheritConfig({
				{ Damage = 40 },
				{ Damage = 20, Range = 100 },
			})

			expect(result).toEqual({ Damage = 40, Range = 100 })
		end)

		it("merges nested tables recursively", function()
			local result = TableInheritUtil.inheritConfig({
				{ Limits = { Max = 50 } },
				{ Limits = { Min = 10, Max = 100 } },
			})

			expect(result).toEqual({ Limits = { Min = 10, Max = 50 } })
		end)

		it("does not mutate the input configs or share nested tables", function()
			local specific: { [string]: any } = { Settings = { Enabled = true } }
			local defaults: { [string]: any } = { Settings = { Enabled = false, Volume = 0.5 } }
			local result = TableInheritUtil.inheritConfig({ specific, defaults })

			result.Settings.Volume = 1
			expect(specific.Settings.Volume).toBe(nil)
			expect(defaults.Settings.Volume).toBe(0.5)
		end)

		it("rejects an empty config list", function()
			expect(function()
				TableInheritUtil.inheritConfig({})
			end).toThrow()
		end)
	end)
end)
