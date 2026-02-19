return {
	-- DAMAGE
	HumanoidDamage = 90, -- Damage to humanoids

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

	-- BALLISTICS
	MaxDistance = 1500, -- Max distance this munition can travel in studs
	EnableDropoff = true,
	DropoffConfig = {
		DropoffStartDistance = 100,
		DropoffEndDistance = 300,
	},

	EnableBallistics = true, -- Should this munition use simple raycast or more advanced physics?
	BallisticConfig = {
		Speed = 1300, -- Projectile speed studs per second
	},
}
