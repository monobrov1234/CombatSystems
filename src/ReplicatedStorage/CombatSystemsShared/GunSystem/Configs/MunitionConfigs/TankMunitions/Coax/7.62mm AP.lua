local DefaultConfig = require(game:GetService("ReplicatedStorage").CombatSystemsShared.GunSystem.Configs.MunitionConfigs.Default.DefaultConfig)

local config
config = {
	-- DAMAGE
	HumanoidDamage = 7, -- Damage to humanoids

	-- VISUALS
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
		EnableTense = true,
		TenseConfig = {
			StayTime = 1,
			TransparencyMultiplier = 1,
			FadeOutTimeMultiplier = 1,
		},

		EnableCameraShake = true,
		TrailCameraShakeConfig = { -- a little camera shake, will not affect your ability to aim much but will be more immersive
			MagnitudeMult = 1,
			Roughness = 4,
			FadeInTime = 0.1,
			FadeOutTime = 0.2,
			PosInfluence = Vector3.new(0.15, 0.15, 0.15),
			RotInfluence = Vector3.new(0.8, 0.8, 0.8),
		},
	},

	ObjectDamageConfig = { -- How much damage this munition does to destructible objects that also can have armor
		["NoArmor"] = 5, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
		["BulletProofArmor"] = 2, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
	},
} :: typeof(DefaultConfig)

return config
