return {
	-- Bullet drop / range indicator style
	-- • "None"       → no drop indicator at all
	-- • "Automatic"  → instantly shows calculated impact point
	-- • "Manual"     → shows calculation progress bar when P button is pressed
	DropIndicatorType = "None" :: "None" | "Automatic" | "Manual",
	-- Time (seconds) required to fully calculate trajectory in Manual mode
	DropManualCalcDuration = 1.5,
	-- How long (seconds) the manual drop indicator remains visible after calculation completes
	DropManualStayDuration = 1.5,

	SeatConfig = {
		-- Hold duration (seconds) for the ProximityPrompt to enter the turret
		PromptHoldDuration = 0.5,
		-- Maximum distance (studs) at which the prompt appears and can be triggered
		PromptDistance = 10,
		-- If set — player must be in **at least one** of these Roblox group IDs to operate the turret
		-- Example: {1234567, 8901234}
		GroupWhitelist = nil :: { number }?,
		-- If set — player must belong to **one** of these Team names
		-- Example: {"Red", "Blue", "Defenders"}
		TeamWhitelist = nil :: { string }?,
	},

	DecorConfig = {
		SoundsConfig = {
			-- Main gun firing sound
			FireSound = nil :: Sound?,
			-- Main gun reload / ready sound
			ReloadSound = nil :: Sound?,
			-- Sound played when switching ammunition type (V)
			SwitchSound = nil :: Sound?,

			-- Sound played when selecting the coaxial machine gun
			CoaxSelectSound = script.CoaxSelect :: Sound?,
			-- Short sound played when turret traversal starts (hydraulics/electric whine)
			TraverseStartSound = script.Start :: Sound?,
			-- Looping traversal sound
			TraverseSound = script.Traverse :: Sound?,
			-- Sound played when turret stops rotating
			TraverseEndSound = script.End :: Sound?,
		},
	},


	GunConfig = {
		-- Rate of fire in Rounds Per Minute (RPM)
		-- Examples: 6 → very slow cannon, 120 → autocannon, 600–900 → machine gun
		FirerateRPM = 1,
		-- Full reload duration (seconds)
		ReloadDuration = 3,
		-- Number of rounds that can be fired before a reload is required
		-- Typical values: 1 (large cannons), 4–15 (autocannons), 200–250 (MGs)
		ClipSize = 1,

		-- Ammunition types and quantities stored for the main gun
		-- Leave empty here (in default config) if you don't want all the turrets default to use same ammo type (cannot be overwritten in turret config)
		AmmoTypes = {} :: { { name: string, stored: number } },

		SpreadConfig = {
			-- Base horizontal (yaw) dispersion in degrees
			Yaw = 0,
			-- Base vertical (pitch) dispersion in degrees
			Pitch = 0,
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

		-- Whether a coaxial machine gun is available
		EnableCoax = false,
		-- Configuration module for the coaxial weapon
		CoaxConfig = require(script.Parent.Parent.Coax["Tank 7.62mm"]),
	},


	ZoomConfig = {
		-- Available zoom levels in first-person view (FOV reduction percentages)
		-- 0    → no zoom
		-- 20   → light zoom
		-- 40+  → telescopic / high-magnification sight
		ZoomSteps = { 0, 20, 40 } :: { number },
	},


	LimitsConfig = {
		-- Maximum turret traverse speed (degrees per second)
		YawSpeed = 35,
		-- Maximum gun elevation / depression speed (degrees per second)
		PitchSpeed = 35,

		-- Neutral / forward-facing yaw angle relative to vehicle hull (degrees)
		-- Usually 90 = straight forward
		YawCenter = 90,
		-- Maximum yaw rotation to the **left** from center
		YawLeftLimit = 180,
		-- Maximum yaw rotation to the **right** from center
		YawRightLimit = 180,

		-- Neutral gun elevation angle (degrees)
		-- 0   → perfectly horizontal
		PitchCenter = 0,
		-- Maximum elevation (gun pointing up) from center
		PitchUpLimit = 20,
		-- Maximum depression (gun pointing down) from center
		PitchDownLimit = 10,
	},
}