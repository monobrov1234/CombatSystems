return {
	Tag = "DestructibleObject", -- If instance has this tag, it will be destructible
	HealthAttribute = "DObjectHealth", -- Health of destructible object, will be decreased when object hit by something (bullet)
	MaxHealthAttribute = "DObjectMaxHealth", -- Max health of destructible object, can be used for UIs, future use like repair mechanics
	ArmorAttribute = "DObjectArmor",
	ArmorResistanceAttribute = "DObjectArmorResist", -- if you want to make armor receive less damage without adding a new armor type, you can set this attribute to a resistance percent number
	ArmorTypes = { -- Armor types, first type is the default type
		"NoArmor", -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
		"BulletProofArmor", -- Protected from standard caliber bullets - typical vehicle armor
		"LightArmor", -- Protected from high caliber bullets, explosions, HE shells - typical armored car armor (also tanks rear can have light armor)
		"MediumArmor", -- Protected from small caliber AP shells (typically armored cars use those) - typical tank armor
		"MediumHeavyArmor", -- Takes less damage from standard caliber AP shells than medium armor, for usage in tank front lower plates
		"HeavyArmor", -- Protected from standard caliber AP shells - typical tank armor infront
		"SuperHeavyArmor", -- Protected from everything except powerful shells (tank destroyer, direct hit from artillery, ATGM) - typical armor for overpowered shit
	},
}
