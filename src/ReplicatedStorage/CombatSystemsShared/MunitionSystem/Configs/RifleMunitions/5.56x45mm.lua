-- config for general use in rifles (like D-19, BR-18)

return {
	HumanoidDamage = 16,
	HeadshotMultiplier = 1.5,
	CanDamageSelf = false,
	CanDamageFriendly = false,

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

	ObjectDamageConfig = {
		["NoArmor"] = 5,
	},

	CanSuppress = true,

	MaxDistance = 3000,
	EnableDropoff = true,
	DropoffConfig = {
		DropoffStartDistance = 60,
		DropoffEndDistance = 1200,
	},

	EnableBallistics = true,
	BallisticConfig = {
		Speed = 4000,
		Gravity = Vector3.new(0, -workspace.Gravity, 0),
		HighFidelitySegmentSize = 0.5,
	},

	ExplosionConfig = {
		CanExplode = false,
	},
}
