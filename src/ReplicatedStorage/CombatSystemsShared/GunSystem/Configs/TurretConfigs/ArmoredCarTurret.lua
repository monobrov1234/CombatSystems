return {
	DropIndicatorType = "Manual", -- Automatic, Manual, None; will enable second cursor that will determine bullet drop

	DecorConfig = {
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
			SwitchSound = script.Switch,
		},
	},

	GunConfig = { -- gun specs
		FirerateRPM = 110, -- To calculate how much delay will be between shots, rounds per minute
		ClipSize = 6, -- How much rounds turret can shoot before reloading
		ReloadDuration = 5, -- How much time it takes to reload the turret in seconds
		AmmoTypes = { -- How much rounds of each type are stored in main gun
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

		EnableCoax = false, -- Coaxial machine gun
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
