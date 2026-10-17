-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerTeamCheckUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.PlayerTeamCheckUtil)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("PlayerTeamCheckUtil", function()
	describe("isInAnyWhitelistedTeam", function()
		it("returns true when the player's team is whitelisted", function()
			local player = { Team = { Name = "Blue" } } :: any

			expect(PlayerTeamCheckUtil.isInAnyWhitelistedTeam(player, { "Red", "Blue" })).toBe(true)
		end)

		it("returns false when the player's team is not whitelisted", function()
			local player = { Team = { Name = "Green" } } :: any

			expect(PlayerTeamCheckUtil.isInAnyWhitelistedTeam(player, { "Red", "Blue" })).toBe(false)
		end)

		it("returns false when the player has no team", function()
			local player = { Team = nil } :: any

			expect(PlayerTeamCheckUtil.isInAnyWhitelistedTeam(player, { "Blue" })).toBe(false)
		end)

		it("returns false for an empty whitelist", function()
			local player = { Team = { Name = "Blue" } } :: any

			expect(PlayerTeamCheckUtil.isInAnyWhitelistedTeam(player, {})).toBe(false)
		end)
	end)
end)
