return {
	-- DAMAGE
	HumanoidDamage = 150, -- Damage to humanoids

	-- VISUALS
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
		}, -- custom handler
	},

	-- TODO
	ObjectDamageConfig = { -- How much damage this munition does to destructible objects that also can have armor
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

	-- BALLISTICS
	EnableBallistics = true, -- Should this munition use simple raycast or more advanced physics?
	BallisticConfig = {
		Speed = 750, -- Projectile speed studs per second
		HighFidelitySegmentSize = 0.25, -- higher resolution because this munition fires not often
	},
}
