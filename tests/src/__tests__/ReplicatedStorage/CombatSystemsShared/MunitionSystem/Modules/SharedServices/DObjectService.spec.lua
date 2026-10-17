-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DObjectService = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedServices.DObjectService)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.DestructibleObjectConfig)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

describe("DObjectService", function()
	local part
	local parent

	beforeEach(function()
		parent = Instance.new("Model")
		part = Instance.new("Part")
		part.Parent = parent
	end)

	afterEach(function()
		parent:Destroy()
	end)

	it("uses the default armor type when no ancestor has an armor type", function()
		local armorInfo = DObjectService.findFirstArmorInfo(part)

		expect(armorInfo).toEqual({ ArmorType = "NoArmor", Resistance = 0 })
	end)

	it("finds the nearest ancestor armor type", function()
		parent:SetAttribute(DestructibleObjectConfig.ArmorAttribute, "HeavyArmor")
		part:SetAttribute(DestructibleObjectConfig.ArmorAttribute, "LightArmor")

		local armorInfo = DObjectService.findFirstArmorInfo(part)

		expect(armorInfo.ArmorType).toBe("LightArmor")
	end)

	it("uses the nearest numeric armor resistance", function()
		part:SetAttribute(DestructibleObjectConfig.ArmorAttribute, "LightArmor")
		parent:SetAttribute(DestructibleObjectConfig.ArmorResistanceAttribute, 40)
		part:SetAttribute(DestructibleObjectConfig.ArmorResistanceAttribute, 15)

		local armorInfo = DObjectService.findFirstArmorInfo(part)

		expect(armorInfo.Resistance).toBe(15)
	end)

	it("reduces configured damage by armor resistance", function()
		parent:SetAttribute(DestructibleObjectConfig.ArmorAttribute, "HeavyArmor")
		parent:SetAttribute(DestructibleObjectConfig.ArmorResistanceAttribute, 25)
		local config = {
			ObjectDamageConfig = {
				NoArmor = 100,
				HeavyArmor = 80,
			},
		} :: any

		expect(DObjectService.getDamageForPart(config, part)).toBe(60)
	end)
end)
