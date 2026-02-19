return {
	Description = "5.56x45mm Battle Rifle",

	DecorConfig = {
		AnimationsFolder = script.Animations,
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
		},
	},

	GunConfig = {
		FirerateRPM = 750,
		ReloadDuration = 2,
		MagSize = 30,
		AmmoSize = 10000,
		AmmoType = "5.56x45mm",

		SpreadConfig = {
			Yaw = 0.3,
			Pitch = 0.3,
		},
	},
}
