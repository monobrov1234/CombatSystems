return {
	DropIndicatorType = "Manual",

	DecorConfig = {
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
			SwitchSound = script.Switch,
		},
	},

	GunConfig = {
		FirerateRPM = 110,
		ReloadDuration = 5,
		ClipSize = 6,
		
		AmmoTypes = {
			{ name = "20mm AP", stored = 100 },
			{ name = "20mm HE", stored = 100 },
		},

		SpreadConfig = {
			Yaw = 0.2,
			Pitch = 0.2,
		},

		RecoilConfig = {
			Yaw = -2.5,
			Pitch = 2.5,
			Strength = 1,
			LerpTime = 0.2,
		},

		EnableCoax = false,
	},

	LimitsConfig = {
		YawLeftLimit = 180,
		YawRightLimit = 180,
		PitchUpLimit = 20,
		PitchDownLimit = 10,
		YawSpeed = 50,
		PitchSpeed = 50,
	},
}
