return {
	Description = "Default gun", -- Description of the gun, displayed in the gun HUD

	FirerateRPM = 650, -- Rate of fire in rounds per minute
	AutoFire = true, -- Gun will automatically fire when the player is holding the fire button
	ReloadDuration = 3, -- Duration of the reload in seconds
	MagSize = 30, -- Size of the magazine
	AmmoSize = 250, -- Size of the ammo
	AmmoType = "RifleDefault", -- Type of ammo (munition name)

	DecorConfig = {
		AnimationsFolder = (nil :: any) :: Folder, -- Folder containing the animations for the gun
		SoundsConfig = {
			FireSound = nil :: Sound?, -- Sound played when the gun is fired
			ReloadSound = nil :: Sound?, -- Sound played when the gun is reloaded
		},
	},

	SpreadConfig = {
		Yaw = 0.1, -- Yaw (horizontal) spread in degrees
		Pitch = 0.1, -- Pitch (vertical) spread in degrees
		InAirSpreadMultiplier = 1.5, -- Spread is multiplied by this value when the player is in the air
		CrouchingSpreadMultiplier = 0.6, -- Spread is multiplied by this value when the player is crouching
		ZoomSpreadMultiplier = 0.85, -- Spread is multiplied by this value when the gun is zoomed
		-- NOTE: Only one zoom spread multiplier will be applied at a time, combo like crouching and zoom is not allowed
	},

	RecoilConfig = {
		Yaw = 0, -- Maximum yaw deviation caused by recoil (degrees)
		Pitch = 0, -- Maximum pitch deviation caused by recoil (degrees, usually upward)
		Strength = 0, -- Overall recoil strength (affects camera shake & kick force)
		LerpTime = 0, -- Recoil smoothing
	},

	ZoomConfig = {
		ZoomEnabled = false,
		ZoomStrength = 20,
		ZoomTweenDuration = 0.2,
	}
}
