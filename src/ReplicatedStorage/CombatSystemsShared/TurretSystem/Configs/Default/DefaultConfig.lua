return {
	DropIndicatorType = "None", -- Automatic, Manual, None; will enable second cursor that will determine bullet drop
	DropManualCalcDuration = 1.5, -- speed of manual drop indicator calculation
	DropManualStayDuration = 1.5, -- how long will manual drop indicator stay on the screen

	SeatConfig = {
		PromptHoldDuration = 0.5, -- proximity prompt hold duration
		PromptDistance = 10, -- proximity prompt activation distance
		GroupWhitelist = nil :: { number }?, -- player will be required to be in those groups to operate the turret if its stationary
	},

	DecorConfig = {
		SoundsConfig = {
			FireSound = nil :: Sound?,
			ReloadSound = nil :: Sound?,
			SwitchSound = nil :: Sound?,
			CoaxSelectSound = script.CoaxSelect :: Sound?,
			TraverseStartSound = script.Start :: Sound?,
			TraverseSound = script.Traverse :: Sound?,
			TraverseEndSound = script.End :: Sound?,
		},
	},

	GunConfig = { -- gun specs
		FirerateRPM = 1, -- To calculate how much delay will be between shots, rounds per minute
		ReloadDuration = 3, -- How much time it takes to reload the turret in seconds
		ClipSize = 1, -- How much rounds turret can shoot before reloading
		AmmoTypes = { -- How much rounds of each type are stored in main gun
			--{name = "APDS", stored = 80}, dont uncomment / put anything here, otherwise it will be applied to EVERY turret, and will be impossible to overwrite
			--{name = "HE", stored = 30},
		} :: { { name: string, stored: number } },
		SpreadConfig = {
			Yaw = 0,
			Pitch = 0,
		},
		RecoilConfig = {
			Yaw = 0,
			Pitch = 0,
			Strength = 0,
			LerpTime = 0,
		},

		EnableCoax = false, -- Coaxial machine gun
		CoaxConfig = require(script.Parent.Parent.Coax["Tank 7.62mm"]),
	},

	ZoomConfig = { -- zoom on first person mode
		ZoomSteps = { 0, 20, 40 },
	},

	LimitsConfig = { -- rotation axis limits
		YawSpeed = 35,
		PitchSpeed = 35,

		YawCenter = 90,
		YawLeftLimit = 180,
		YawRightLimit = 180,
		PitchCenter = 0,
		PitchUpLimit = 20,
		PitchDownLimit = 10,
	},
}
