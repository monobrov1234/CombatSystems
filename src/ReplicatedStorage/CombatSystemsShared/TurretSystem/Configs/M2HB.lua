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
			{ name = "MG Non-Lethal", stored = 500 },
		},

		SpreadConfig = {
			Yaw = 0.7,
			Pitch = 0.7,
		},
	},

	LimitsConfig = {
		YawLeftLimit = 45,
		YawRightLimit = 45,
		PitchUpLimit = 10,
		PitchDownLimit = 10,
		YawSpeed = 90,
		PitchSpeed = 90,
	},
}
