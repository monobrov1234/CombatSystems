local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.DestructibleObjectConfig)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.DestructibleObject.DestructibleObject)

-- PUBLIC API

function module.getDamageForPart(config: MunitionConfigUtil.DefaultType, part: BasePart)
	local foundArmorInfo: DestructibleObject.ArmorInfo = module.findFirstArmorInfo(part)
	local totalDamage: number = config.ObjectDamageConfig[foundArmorInfo.ArmorType]
	assert(totalDamage, "Munition object damage config doesn't have value for armor type " .. foundArmorInfo.ArmorType)

	local resistDamage = totalDamage * (1 - foundArmorInfo.Resistance / 100)
	return resistDamage
end

-- search ancestor tree up until ancestor with armor type tag is found, if nothing found - defaulting to first element in ArmorTypes array
function module.findFirstArmorInfo(basePart: BasePart): DestructibleObject.ArmorInfo
	local armorInfo: DestructibleObject.ArmorInfo = {
		ArmorType = DestructibleObjectConfig.ArmorTypes[1],
		Resistance = 0,
	}

	local armorAncestor: Instance? = basePart
	while armorAncestor do
		local found = false
		for _, armorType: string in ipairs(DestructibleObjectConfig.ArmorTypes) do
			if armorAncestor:GetAttribute(DestructibleObjectConfig.ArmorAttribute) == armorType then
				armorInfo.ArmorType = armorType
				armorInfo.Resistance = funcs.findFirstArmorResistance(basePart)
				found = true
				break
			end
		end

		if found then break end
		armorAncestor = armorAncestor.Parent
	end

	return armorInfo
end

-- INTERNAL FUNCTIONS
-- search ancestor tree up until DestructibleObjectConfig.ArmorResistanceAttribute is found, if nothing found - return 0
function funcs.findFirstArmorResistance(instance: Instance): number
	local armorResistance: number = 0
	local armorAncestor: Instance? = instance
	while armorAncestor do
		local resistance = armorAncestor:GetAttribute(DestructibleObjectConfig.ArmorResistanceAttribute)
		if resistance and typeof(resistance) == "number" then
			armorResistance = resistance
			break
		end
		armorAncestor = armorAncestor.Parent
	end

	return armorResistance
end

return module
