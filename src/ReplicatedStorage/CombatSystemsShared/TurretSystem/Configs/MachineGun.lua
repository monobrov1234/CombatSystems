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

	GunConfig = {
		FirerateRPM = 600,
		ClipSize = 100,
		ReloadDuration = 3,
		
		AmmoTypes = {
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
