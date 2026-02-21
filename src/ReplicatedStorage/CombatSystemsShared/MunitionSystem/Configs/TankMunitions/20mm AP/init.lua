return {
	HumanoidDamage = 90,

	FXConfig = {
		ShootFXHandler = {
			HandlerModuleName = "FlashShootFXHandler",
		},

		TrailFXHandler = {
			HandlerModuleName = "CosmeticBulletTrailFXHandler",
			HandlerConfig = { CosmeticBullet = script.APBullet },
		},

		ImpactFXHandler = {
			HandlerModuleName = "APDSImpactFXHandler",
			HandlerConfig = {}
		},
	},

	ObjectDamageConfig = {
		["NoArmor"] = 50,
		["BulletProofArmor"] = 30,
		["LightArmor"] = 15,
	},

	CanSuppress = true,
	CanSuppressImpact = true,
	SuppressionConfig = {
		EnableTense = true,
		TenseConfig = {
			StayTime = 2,
			TransparencyMultiplier = 0.1,
			FadeOutTimeMultiplier = 2,
		},

		EnableCameraShake = true,
		TrailCameraShakeConfig = nil,
		ImpactCameraShakeConfig = {
			MagnitudeMult = 5,
			Roughness = 8,
			FadeInTime = 0,
			FadeOutTime = 0.25,
			PosInfluence = Vector3.new(0.25, 0.25, 0.25),
			RotInfluence = Vector3.new(5, 5, 1),
		},
	},

	MaxDistance = 1500,
	EnableDropoff = true,
	DropoffConfig = {
		DropoffStartDistance = 100,
		DropoffEndDistance = 300,
	},

	EnableBallistics = true,
	BallisticConfig = {
		Speed = 1300,
	},
}
