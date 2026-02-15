-- config for general use in rifles (like D-19, BR-18)

local DefaultConfig = require(game:GetService("ReplicatedStorage").CombatSystemsShared.GunSystem.Configs.MunitionConfigs.Default.DefaultConfig)

return {
	-- DAMAGE
	HumanoidDamage = 16, -- Damage to humanoids
	HeadshotMultiplier = 1.5,
	CanDamageSelf = false,
	CanDamageFriendly = false,

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

	ObjectDamageConfig = { -- How much damage this munition does to destructible objects that also can have armor
		["NoArmor"] = 5, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
	},

	CanSuppress = true,

	MaxDistance = 3000,
	EnableDropoff = true,
	DropoffConfig = {
		DropoffStartDistance = 60,
		DropoffEndDistance = 1200,
	},

	EnableBallistics = true,
	BallisticConfig = {
		Speed = 4000,
		Gravity = Vector3.new(0, -workspace.Gravity, 0),
		HighFidelitySegmentSize = 0.5,
	},

	ExplosionConfig = {
		CanExplode = false,
	},
} :: typeof(DefaultConfig)
