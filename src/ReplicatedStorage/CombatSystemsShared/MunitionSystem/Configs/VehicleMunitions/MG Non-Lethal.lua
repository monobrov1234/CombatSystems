return {
	HumanoidDamage = 0.5,

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

	CanSuppress = true,
	CanSuppressImpact = false,
	SuppressionConfig = {
		EnableTense = false,
		TenseConfig = {
			StayTime = 1,
			TransparencyMultiplier = 1,
			FadeOutTimeMultiplier = 1,
		},

		EnableCameraShake = true,
		TrailCameraShakeConfig = {
			MagnitudeMult = 1,
			Roughness = 3,
			FadeInTime = 0.1,
			FadeOutTime = 0.2,
			PosInfluence = Vector3.new(0.15, 0.15, 0.15),
			RotInfluence = Vector3.new(0.6, 0.6, 0.6),
		},
	},

	ObjectDamageConfig = {
		["NoArmor"] = 0.2,
		["BulletProofArmor"] = 0.05,
	},
}
