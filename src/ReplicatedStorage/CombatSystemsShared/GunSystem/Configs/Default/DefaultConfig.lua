return {
	Description = "Default gun",

	DecorConfig = {
		AnimationsFolder = (nil :: any) :: Folder,
		SoundsConfig = {
			FireSound = nil :: Sound?,
			ReloadSound = nil :: Sound?,
		},
	},

	GunConfig = {
		FirerateRPM = 650,
		ReloadDuration = 3,
		MagSize = 30,
		AmmoSize = 250,
		AmmoType = "RifleDefault",

		SpreadConfig = {
			Yaw = 0.1,
			Pitch = 0.1,
		},

		RecoilConfig = {
			Yaw = 0,
			Pitch = 0,
			Strength = 0,
			LerpTime = 0,
		},
	},
}
