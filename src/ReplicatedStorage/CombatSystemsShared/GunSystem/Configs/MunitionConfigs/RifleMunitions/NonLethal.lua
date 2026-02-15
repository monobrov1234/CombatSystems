-- config for training rifles / turrets

local DefaultConfig = require(game:GetService("ReplicatedStorage").CombatSystemsShared.GunSystem.Configs.MunitionConfigs.Default.DefaultConfig)

return {
	-- DAMAGE
	HumanoidDamage = 0, -- Damage to humanoids

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
} :: typeof(DefaultConfig)
