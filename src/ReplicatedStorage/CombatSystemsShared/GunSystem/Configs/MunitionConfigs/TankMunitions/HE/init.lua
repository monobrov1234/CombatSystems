return {
	-- DAMAGE
	HumanoidDamage = 100, -- Damage to humanoids

	-- VISUALS
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
		}, -- custom handler
	},

	ObjectDamageConfig = { -- How much damage this munition does to destructible objects that also can have armor
		["NoArmor"] = 50, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
		["BulletProofArmor"] = 20, -- Protected from standard caliber bullets - typical vehicle armor
		["LightArmor"] = 1,
	},

	ExplosionConfig = {
		CanExplode = true, -- Does this munition explode on impact?
		HumanoidDamage = 100, -- Damage to humanoids
		Radius = 15, -- Radius of explosion
		DropoffStartRadius = 6, -- Radius where damage will start to drop off, anything within this radius will receive 100% damage

		ObjectDamageConfig = { -- How much damage this explosion does to destructible objects that also can have armor
			["NoArmor"] = 30, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
			["BulletProofArmor"] = 30, -- Protected from standard caliber bullets - typical vehicle armor
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

	-- BALLISTICS
	EnableBallistics = true, -- Should this munition use simple raycast or more advanced physics?
	BallisticConfig = {
		Speed = 750, -- Projectile speed studs per second
	},
}
