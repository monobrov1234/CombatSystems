return {
	Description = "Training Rifle",

	FirerateRPM = 550,
	ReloadDuration = 3,
	MagSize = 30,
	AmmoSize = 10000,
	AmmoType = "Training Round",

	DecorConfig = {
		AnimationsFolder = script.Animations,
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
		},
	},

	SpreadConfig = {
		Yaw = 0.55,
		Pitch = 0.55,
	},

	ZoomConfig = {
		ZoomEnabled = true,
		ZoomStrength = 20
	}
}
