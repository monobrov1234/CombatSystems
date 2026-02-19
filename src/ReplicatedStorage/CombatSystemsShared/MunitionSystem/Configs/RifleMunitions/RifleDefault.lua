-- config for general use in rifles (like D-19, BR-18)

return {
	-- DAMAGE
	HumanoidDamage = 8, -- Damage to humanoids

	-- VISUALS
	FXConfig = {
		ShootFXHandler = {
			HandlerModuleName = "FlashShootFXHandler",
		},

		TrailFXHandler = {
			HandlerModuleName = "FakeProjectileTrailFXHandler",
			HandlerConfig = { CosmeticBullet = script.Bullet },
		},

		ImpactFXHandler = {
			HandlerModuleName = "BulletImpactFXHandler",
			HandlerConfig = { Color = ColorSequence.new(Color3.new(1, 1, 1)) },
		},
	},

	ObjectDamageConfig = { -- How much damage this munition does to destructible objects that also can have armor
		["NoArmor"] = 1, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
	},
}
