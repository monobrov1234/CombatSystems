return {
	Description = "5.56x45mm Battle Rifle",

	FirerateRPM = 750,
	ReloadDuration = 3,
	MagSize = 30,
	AmmoSize = 10000,
	AmmoType = "5.56x45mm",

	DecorConfig = {
		AnimationsFolder = script.Animations,
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
		},
	},

	SpreadConfig = {
		Yaw = 0.3,
		Pitch = 0.3,
	},

	ZoomConfig = {
		ZoomEnabled = true,
		ZoomStrength = 20
	}
}
