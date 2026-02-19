return {
	-- DAMAGE
	HumanoidDamage = 80, -- Damage to humanoids

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
		["BulletProofArmor"] = 10, -- Protected from standard caliber bullets - typical vehicle armor
	},

	ExplosionConfig = {
		CanExplode = true, -- Does this munition explode on impact?
		HumanoidDamage = 80, -- Damage to humanoids
		Radius = 12, -- Radius of explosion
		DropoffStartRadius = 2, -- Radius where damage will start to drop off, anything within this radius will receive 100% damage

		ObjectDamageConfig = { -- How much damage this explosion does to destructible objects that also can have armor
			["NoArmor"] = 20, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
			["BulletProofArmor"] = 10, -- Protected from standard caliber bullets - typical vehicle armor
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
