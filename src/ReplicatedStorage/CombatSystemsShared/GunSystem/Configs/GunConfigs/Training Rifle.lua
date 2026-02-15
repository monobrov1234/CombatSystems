return {
	Description = "Non-Lethal Training Rifle",

	DecorConfig = {
		AnimationsFolder = script.Animations,
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
		},
	},

	GunConfig = {
		FirerateRPM = 550,
		ReloadDuration = 3,
		MagSize = 30,
		AmmoSize = 10000,
		AmmoType = "NonLethal",

		SpreadConfig = {
			Yaw = 0.55,
			Pitch = 0.55,
		},
	},
}
