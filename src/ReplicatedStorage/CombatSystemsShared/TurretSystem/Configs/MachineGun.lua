return {
	DecorConfig = {
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
			SwitchSound = script.Reload,
			TraverseStartSound = false,
			TraverseSound = false,
			TraverseEndSound = false,
		},
	},

	GunConfig = { -- gun specs
		FirerateRPM = 600, -- To calculate how much delay will be between shots, rounds per minute
		ClipSize = 100, -- How much rounds turret can shoot before reloading
		ReloadDuration = 3, -- How much time it takes to reload the turret in seconds
		AmmoTypes = { -- How much rounds of each type are stored in main gun
			{ name = "7.62mm AP", stored = 500 },
		},
		SpreadConfig = {
			Yaw = 0.35,
			Pitch = 0.35,
		},
	},

	LimitsConfig = {
		YawLeftLimit = 180,
		YawRightLimit = 180,
		PitchUpLimit = 10,
		PitchDownLimit = 10,
		YawSpeed = 90,
		PitchSpeed = 90,
	},
}
