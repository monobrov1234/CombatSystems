return {
	DropIndicatorType = "Automatic",

	DecorConfig = {
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
			SwitchSound = script.SwitchReload,
		},
	},

	GunConfig = {
		FirerateRPM = 45,
		ClipSize = 1,
		ReloadDuration = 5,
		AmmoTypes = {
			{ name = "APDS", stored = 60 },
			{ name = "HE", stored = 40 },
		},

		SpreadConfig = {
			Yaw = 0.05,
			Pitch = 0.05,
		},

		RecoilConfig = {
			Yaw = -25,
			Pitch = 15,
			Strength = 0.9,
			LerpTime = 0.2,
		},

		EnableCoax = true,
		CoaxConfig = require(script.Parent.Coax["Tank 7.62mm"]),
	},

	LimitsConfig = {
		YawLeftLimit = 180,
		YawRightLimit = 180,
		PitchUpLimit = 25,
		PitchDownLimit = 10,
		YawSpeed = 40,
		PitchSpeed = 40,
	},
}
