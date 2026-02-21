return {
	HumanoidDamage = 100,

	FXConfig = {
		ShootFXHandler = {
			HandlerModuleName = "FlashShootFXHandler",
		},

		TrailFXHandler = {
			HandlerModuleName = "CosmeticBulletTrailFXHandler",
			HandlerConfig = { CosmeticBullet = script.HEBullet },
		},

		ImpactFXHandler = {
			HandlerModuleName = "HEImpactFXHandler",
			HandlerConfig = {}
		},
	},

	ObjectDamageConfig = {
		["NoArmor"] = 50,
		["BulletProofArmor"] = 20,
		["LightArmor"] = 1,
	},

	ExplosionConfig = {
		CanExplode = true,
		HumanoidDamage = 100,
		Radius = 15,
		DropoffStartRadius = 6,

		ObjectDamageConfig = {
			["NoArmor"] = 30,
			["BulletProofArmor"] = 30,
		},
	},

	CanSuppress = true,
	CanSuppressImpact = true,
	SuppressionConfig = {
		EnableTense = true,
		TenseConfig = {
			StayTime = 3,
			TransparencyMultiplier = 0.1,
			FadeOutTimeMultiplier = 2,
		},

		EnableCameraShake = true,
		TrailCameraShakeConfig = nil,
		ImpactCameraShakeConfig = {
			MagnitudeMult = 6,
			Roughness = 12,
			FadeInTime = 0,
			FadeOutTime = 0.4,
			PosInfluence = Vector3.new(0.5, 0.5, 0.5),
			RotInfluence = Vector3.new(18, 18, 1),
		},
	},

	EnableBallistics = true,
	BallisticConfig = {
		Speed = 750,
	},
}
