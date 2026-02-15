return {
	DropIndicatorType = "Manual", -- Automatic, Manual, None; will enable second cursor that will determine bullet drop

	DecorConfig = {
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
			SwitchSound = script.SwitchReload,
		},
	},

	GunConfig = { -- gun specs
		FirerateRPM = 45, -- To calculate how much delay will be between shots, rounds per minute
		ClipSize = 1, -- How much rounds turret can shoot before reloading
		ReloadDuration = 5.5, -- How much time it takes to reload the turret in seconds
		AmmoTypes = { -- How much rounds of each type are stored in main gun
			{ name = "APDS", stored = 50 },
			{ name = "HE", stored = 30 },
		},

		SpreadConfig = {
			Yaw = 0.1,
			Pitch = 0.1,
		},

		RecoilConfig = {
			Yaw = -40,
			Pitch = 20,
			Strength = 1,
			LerpTime = 0.2,
		},

		EnableCoax = true, -- Coaxial machine gun
		CoaxConfig = require(script.Parent.Coax["Tank 7.62mm"]),
	},

	LimitsConfig = {
		YawLeftLimit = 180,
		YawRightLimit = 180,
		PitchUpLimit = 20,
		PitchDownLimit = 10,
		YawSpeed = 35,
		PitchSpeed = 35,
	},
}
