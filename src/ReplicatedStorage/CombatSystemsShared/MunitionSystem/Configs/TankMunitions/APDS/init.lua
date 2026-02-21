return {
	HumanoidDamage = 150,

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
		["NoArmor"] = 150,
		["BulletProofArmor"] = 150,
		["LightArmor"] = 50,
		["MediumArmor"] = 35,
		["MediumHeavyArmor"] = 10,
		["HeavyArmor"] = 1,
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
			Roughness = 10,
			FadeInTime = 0,
			FadeOutTime = 0.3,
			PosInfluence = Vector3.new(0.35, 0.35, 0.35),
			RotInfluence = Vector3.new(10, 10, 1),
		},
	},

	EnableBallistics = true,
	BallisticConfig = {
		Speed = 750,
		HighFidelitySegmentSize = 0.25,
	},
}
