-- IMPORTS
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.GunSystemConfig)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

describe("GunUtil", function()
	local gunTool

	beforeEach(function()
		gunTool = Instance.new("Tool")
	end)

	afterEach(function()
		gunTool:Destroy()
	end)

	it("recognizes a tool with the gun tag", function()
		CollectionService:AddTag(gunTool, GunSystemConfig.Tag)

		expect(GunUtil.validateGun(gunTool)).toBe(true)
	end)

	it("rejects a tool without the gun tag", function()
		expect(GunUtil.validateGun(gunTool)).toBe(false)
	end)
end)
