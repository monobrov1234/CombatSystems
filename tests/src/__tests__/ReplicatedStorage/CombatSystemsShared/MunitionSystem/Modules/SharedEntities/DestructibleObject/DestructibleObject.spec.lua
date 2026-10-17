-- IMPORTS
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.DestructibleObject.DestructibleObject)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.DestructibleObjectConfig)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

describe("DestructibleObject", function()
	local object

	beforeEach(function()
		object = Instance.new("Model")
		object:SetAttribute(DestructibleObjectConfig.HealthAttribute, 100)
		object:SetAttribute(DestructibleObjectConfig.MaxHealthAttribute, 100)
		CollectionService:AddTag(object, DestructibleObjectConfig.Tag)
	end)

	afterEach(function()
		object:Destroy()
	end)

	it("creates an object from a tagged instance", function()
		local destructibleObject = DestructibleObject.fromInstance(object)

		expect(destructibleObject ~= nil).toBe(true)
	end)

	it("does not create an object from an untagged instance", function()
		CollectionService:RemoveTag(object, DestructibleObjectConfig.Tag)

		expect(DestructibleObject.fromInstance(object)).toBe(nil)
	end)

	it("finds the tagged destructible object from a child instance", function()
		local child = Instance.new("Part")
		child.Parent = object

		local destructibleObject = DestructibleObject.fromInstanceChild(child)

		expect(destructibleObject ~= nil).toBe(true)
	end)

	it("applies damage without allowing health to fall below zero", function()
		local destructibleObject = DestructibleObject.fromInstance(object)
		assert(destructibleObject)

		destructibleObject:takeDamage(150)

		expect(destructibleObject:getHealth()).toBe(0)
		expect(destructibleObject:isDestroyed()).toBe(true)
	end)

	it("updates health and maximum health attributes", function()
		local destructibleObject = DestructibleObject.fromInstance(object)
		assert(destructibleObject)

		destructibleObject:setMaxHealth(200)
		destructibleObject:setHealth(125)

		expect(destructibleObject:getMaxHealth()).toBe(200)
		expect(destructibleObject:getHealth()).toBe(125)
	end)
end)
