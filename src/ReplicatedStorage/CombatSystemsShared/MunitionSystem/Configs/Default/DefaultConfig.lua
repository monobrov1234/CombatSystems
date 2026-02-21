export type FXHandlerType = {
	HandlerModuleName: string,
	HandlerConfig: {},
}

return {
	-- Name of this munition type. Automatically set by the system. Do not change manually.
	MunitionName = "",

	-- Base damage dealt to Humanoids on direct hit
	HumanoidDamage = 0,
	-- Damage multiplier applied when hitting the head
	HeadshotMultiplier = 1.5,
	-- Whether this munition can damage its own shooter (only on explosion)
	CanDamageSelf = false,
	-- Whether this munition can damage friendly players or vehicles
	CanDamageFriendly = false,

	FXConfig = {
		-- Controls firing effects (muzzle flash, smoke, shell ejection etc.)
		ShootFXHandler = nil :: FXHandlerType?,
		-- Controls projectile trail visuals
		TrailFXHandler = nil :: FXHandlerType?,
		-- Controls impact effects (sparks, decals, particles etc.)
		ImpactFXHandler = nil :: FXHandlerType?,
	},

	-- Damage dealt to destructible objects based on armor type (direct hit)
	ObjectDamageConfig = {
		-- Unarmored objects and light cover
		["NoArmor"] = 0,
		-- Bulletproof glass and light vehicle protection
		["BulletProofArmor"] = 0,
		-- Light armored vehicles and tank rear/turret ring
		["LightArmor"] = 0,
		-- Standard tank armor
		["MediumArmor"] = 0,
		-- Reinforced medium armor
		["MediumHeavyArmor"] = 0,
		-- Heavy tank frontal armor
		["HeavyArmor"] = 0,
		-- Fortifications and extremely heavy armor
		["SuperHeavyArmor"] = 0,
	},

	-- Explosion configuration for HE shells, rockets, grenades etc.
	ExplosionConfig = {
		-- Whether the munition explodes on impact
		CanExplode = false,
		-- Explosion damage dealt to Humanoids
		HumanoidDamage = 0,
		-- Maximum explosion radius in studs
		Radius = 0,
		-- Radius in which targets receive 100% explosion damage
		DropoffStartRadius = 0,

		-- Explosion damage to destructible objects based on armor type
		ObjectDamageConfig = {
			-- Unarmored objects and light cover
			["NoArmor"] = 0,
			-- Bulletproof glass and light vehicle protection
			["BulletProofArmor"] = 0,
			-- Light armored vehicles and tank rear/turret ring
			["LightArmor"] = 0,
			-- Standard tank armor
			["MediumArmor"] = 0,
			-- Reinforced medium armor
			["MediumHeavyArmor"] = 0,
			-- Heavy tank frontal armor
			["HeavyArmor"] = 0,
			-- Fortifications and extremely heavy armor
			["SuperHeavyArmor"] = 0,
		},
	},

	-- Whether this munition applies suppression effects to nearby players
	CanSuppress = true,
	-- Whether a direct impact also triggers suppression
	CanSuppressImpact = false,

	SuppressionConfig = {
		-- Enables tense screen overlay effect when suppressed
		EnableTense = true,
		TenseConfig = {
			-- Duration (seconds) the tense effect stays at full intensity
			StayTime = 0,
			-- Intensity of the tense overlay
			TransparencyMultiplier = 1,
			-- Fade-out speed multiplier for tense effect
			FadeOutTimeMultiplier = 1,
		},

		-- Enables camera shake from the munition
		EnableCameraShake = false,
		TrailCameraShakeConfig = {
			-- Strength multiplier of the camera shake
			MagnitudeMult = 2.5,
			-- Roughness / jitter of the shake
			Roughness = 4,
			-- Time to reach full shake intensity (seconds)
			FadeInTime = 0.1,
			-- Time to fade out the shake (seconds)
			FadeOutTime = 0.2,
			-- Influence on camera position
			PosInfluence = Vector3.new(0.15, 0.15, 0.15),
			-- Influence on camera rotation
			RotInfluence = Vector3.new(1, 1, 1),
		},
		-- Camera shake config for direct impacts (nil = use TrailCameraShakeConfig)
		ImpactCameraShakeConfig = nil :: {}?,
	},

	-- Maximum travel distance in studs before despawn
	MaxDistance = 1500,

	-- Enables damage reduction with increasing distance
	EnableDropoff = false,
	DropoffConfig = {
		-- Distance where damage dropoff begins (studs)
		DropoffStartDistance = 100,
		-- Distance where damage reaches minimum (studs)
		DropoffEndDistance = 300,
	},

	-- Enables realistic ballistic simulation (gravity, trajectory arc)
	EnableBallistics = false,
	BallisticConfig = {
		-- Initial projectile speed in studs per second
		Speed = 700,
		-- Gravity vector applied to the projectile
		Gravity = Vector3.new(0, -workspace.Gravity, 0),
		-- Segment size for precise ballistic trajectory (smaller = more accurate)
		HighFidelitySegmentSize = 0.5,
	},
}