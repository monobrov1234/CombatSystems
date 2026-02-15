local DefaultConfig = require(game:GetService("ReplicatedStorage").CombatSystemsShared.GunSystem.Configs.TurretConfigs.Default.DefaultConfig)

return {
	DecorConfig = {
		SoundsConfig = {
			FireSound = script.Fire,
			ReloadSound = script.Reload,
			SwitchSound = script.Reload,
			TraverseStartSound = false,
			TraverseSound = false,
			TraverseEndSound = false,
		},
	},

	GunConfig = { -- gun specs
		FirerateRPM = 500, -- To calculate how much delay will be between shots, rounds per minute
		ClipSize = 100, -- How much rounds turret can shoot before reloading
		ReloadDuration = 3, -- How much time it takes to reload the turret in seconds
		AmmoTypes = { -- How much rounds of each type are stored in main gun
			{ name = "Non-Lethal", stored = 500 },
		},
		SpreadConfig = {
			Yaw = 1,
			Pitch = 1,
		},
	},

	LimitsConfig = {
		YawLeftLimit = 45,
		YawRightLimit = 45,
		PitchUpLimit = 10,
		PitchDownLimit = 10,
		YawSpeed = 90,
		PitchSpeed = 90,
	},
} :: typeof(DefaultConfig)
