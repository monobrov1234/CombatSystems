return {
	HumanoidDamage = 80,

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
			HandlerConfig = {
				ExplosionType = "Small"
			}
		},
	},

	ObjectDamageConfig = {
		["NoArmor"] = 50,
		["BulletProofArmor"] = 10,
	},

	ExplosionConfig = {
		CanExplode = true,
		HumanoidDamage = 80,
		Radius = 12,
		DropoffStartRadius = 2,

		ObjectDamageConfig = {
			["NoArmor"] = 20,
			["BulletProofArmor"] = 10,
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
			MagnitudeMult = 5,
			Roughness = 10,
			FadeInTime = 0,
			FadeOutTime = 0.3,
			PosInfluence = Vector3.new(0.25, 0.25, 0.25),
			RotInfluence = Vector3.new(10, 10, 1),
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
