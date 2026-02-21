return {
	-- Rate of fire in Rounds Per Minute (RPM)
	-- Examples: 6 → very slow cannon, 120 → autocannon, 600–900 → machine gun
	FirerateRPM = 650,
	-- Full reload duration (seconds)
	ReloadDuration = 3,
	-- Number of rounds that can be fired before a reload is required
	-- Typical values: 1 (large cannons), 4–15 (autocannons), 200–250 (MGs)
	ClipSize = 100,
	AmmoType = "7.62mm AP",
	AmmoSize = 500,

	SpreadConfig = {
		-- Base horizontal (yaw) dispersion in degrees
		Yaw = 0.4,
		-- Base vertical (pitch) dispersion in degrees
		Pitch = 0.4,
	},

	RecoilConfig = {
		-- Maximum yaw deviation caused by recoil (degrees)
		Yaw = 0,
		-- Maximum pitch deviation caused by recoil (degrees, usually upward)
		Pitch = 0,
		-- Overall recoil strength (affects camera shake & kick force)
		Strength = 0,
		-- Recoil smoothing
		LerpTime = 0,
	},

	DecorConfig = {
		SoundsConfig = {
			-- Coax gun firing sound
			FireSound = script.FireCoax,
			-- Coax gun reload / ready sound
			ReloadSound = script.ReloadCoax,
		},
	},
}
