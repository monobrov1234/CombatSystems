--!strict

export type FXHandlerType = {
	HandlerModuleName: string,
	HandlerConfig: {},
}

return {
	MunitionName = "", -- will be internally set, dont change

	-- DAMAGE
	HumanoidDamage = 0, -- Damage to humanoids
	HeadshotMultiplier = 1.5,
	CanDamageSelf = false, -- can this munition damage its shooter in any way
	CanDamageFriendly = false, -- can this munition deal damage to friendly players/vehicles

	-- VISUALS
	FXConfig = {
		-- see CombatSystemsClient.MunitionController.FXHandler folder in StarterPlayerScripts for available names and configs
		ShootFXHandler = nil :: FXHandlerType?, -- will handle shoot fx like muzzle flash
		TrailFXHandler = nil :: FXHandlerType?, -- will handle how bullet trail will behave
		ImpactFXHandler = nil :: FXHandlerType?, -- will handle impact effect on bullet hit
	},

	ObjectDamageConfig = { -- How much damage this munition does to destructible objects that also can have armor
		["NoArmor"] = 0, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
		["BulletProofArmor"] = 0, -- Protected from standard caliber bullets - typical vehicle armor
		["LightArmor"] = 0, -- Protected from high caliber bullets, explosions, HE shells - typical armored car armor (also tanks rear can have light armor)
		["MediumArmor"] = 0, -- Protected from small caliber AP shells (typically armored cars use those) - typical tank armor
		["MediumHeavyArmor"] = 0,
		["HeavyArmor"] = 0, -- Protected from standard caliber AP shells - typical tank armor infront
		["SuperHeavyArmor"] = 0, -- Protected from everything except powerful shells (direct hit from artillery, battleship main guns) - typical armor for buildings
	},

	ExplosionConfig = {
		CanExplode = false, -- Does this munition explode on impact?
		HumanoidDamage = 0, -- Damage to humanoids
		Radius = 0, -- Radius of explosion
		DropoffStartRadius = 0, -- Radius where damage will start to drop off, anything within this radius will receive 100% damage

		ObjectDamageConfig = { -- How much damage this explosion does to destructible objects that also can have armor
			["NoArmor"] = 0, -- Protected from small caliber bullets like pistol ammo - typical destructible objects armor
			["BulletProofArmor"] = 0, -- Protected from standard caliber bullets - typical vehicle armor
			["LightArmor"] = 0, -- Protected from high caliber bullets, explosions, HE shells - typical armored car armor (also tanks rear can have light armor)
			["MediumArmor"] = 0, -- Protected from small caliber AP shells (typically armored cars use those) - typical tank armor
			["MediumHeavyArmor"] = 0,
			["HeavyArmor"] = 0, -- Protected from standard caliber AP shells - typical tank armor infront
			["SuperHeavyArmor"] = 0, -- Protected from everything except powerful shells (direct hit from artillery, battleship main guns) - typical armor for buildings
		},
	},

	CanSuppress = true,
	CanSuppressImpact = false,
	SuppressionConfig = {
		EnableTense = true,
		TenseConfig = {
			StayTime = 0,
			TransparencyMultiplier = 1,
			FadeOutTimeMultiplier = 1,
		},

		EnableCameraShake = false,
		TrailCameraShakeConfig = {
			MagnitudeMult = 2.5,
			Roughness = 4,
			FadeInTime = 0.1,
			FadeOutTime = 0.2,
			PosInfluence = Vector3.new(0.15, 0.15, 0.15),
			RotInfluence = Vector3.new(1, 1, 1),
		},
		ImpactCameraShakeConfig = nil :: {}?,
	},

	-- BALLISTICS
	MaxDistance = 1500, -- Max distance this munition can travel in studs
	EnableDropoff = false,
	DropoffConfig = {
		DropoffStartDistance = 100,
		DropoffEndDistance = 300,
	},

	EnableBallistics = false, -- Should this munition use more advanced physics (TODO: maybe move all the physics entirely to fastcast)
	BallisticConfig = { -- Ballistic physics config
		Speed = 700, -- Projectile speed studs per second
		Gravity = Vector3.new(0, -workspace.Gravity, 0), -- Projectile gravity
		HighFidelitySegmentSize = 0.5, -- Resolution of the projectile ballistic tracing
	},
}
