local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.DestructibleObjectConfig)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.DestructibleObject.DestructibleObject)

-- PUBLIC API

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
				armorInfo.Resistance = funcs.getPartResistance(armorAncestor)
				found = true
				break
			end
		end

		if found then break end
		armorAncestor = armorAncestor.Parent
	end

	return armorInfo
end

function module.getDamageForPart(config: MunitionConfigUtil.DefaultType, part: BasePart)
	local foundArmorInfo: DestructibleObject.ArmorInfo = module.findFirstArmorInfo(part)
	local totalDamage: number = config.ObjectDamageConfig[foundArmorInfo.ArmorType]
	assert(totalDamage, "Munition object damage config doesn't have value for armor type " .. foundArmorInfo.ArmorType)

	local resistDamage = totalDamage * (1 - foundArmorInfo.Resistance / 100)
	return resistDamage
end

-- INTERNAL FUNCTIONS
function funcs.getPartResistance(part: Instance): number
	return (part:GetAttribute(DestructibleObjectConfig.ArmorResistanceAttribute) :: number?) or 0
end

return module
