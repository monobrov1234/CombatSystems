return {
	DropIndicatorType = "Manual",

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
		ReloadDuration = 5.5,
		AmmoTypes = {
			{ name = "APDS", stored = 50 },
			{ name = "HE", stored = 30 },
		},

		SpreadConfig = {
			Yaw = 0.1,
			Pitch = 0.1,
		},

		RecoilConfig = {
			Yaw = -30,
			Pitch = 20,
			Strength = 1,
			LerpTime = 0.2,
		},

		EnableCoax = true,
		CoaxConfig = require(script.Parent.Coax["Tank 7.62mm"]),
	},

	LimitsConfig = {
		YawLeftLimit = 180,
		YawRightLimit = 180,
		PitchUpLimit = 20,
		PitchDownLimit = 7,
		YawSpeed = 35,
		PitchSpeed = 35,
	},
}
