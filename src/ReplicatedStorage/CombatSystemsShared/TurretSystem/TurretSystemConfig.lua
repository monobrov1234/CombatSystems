return {
	Tag = "TurretControl", -- will mark that this object is a TurretView compatible
	NameAttribute = "TurretName", -- turret name for finding matching config

	Debug = false, -- will render a ray from the turret
	ReplicationResolution = 1 / 20, -- (20fps) how fast client sends replication packets to server

	DropIndicatorConfig = {
		Resolution = 30, -- The resolution of the projectile trajectory computer,
		-- higher gives better resolution (MAKE 150 FOR PERFECT COMPUTING)
		Steps = 30, -- The steps (length) of a projectile trajectory compute,
		-- higher gives better length but requires more cycles.
		-- Length is computed as "|v|*s" where s is Steps and |v| is length of velocity vector
	},

	-- bindings
	KeyBindings = {
		FirstPersonMode = {
			ToggleKey = Enum.KeyCode.Q,
			ZoomInKey = Enum.KeyCode.LeftShift,
			ZoomOutKey = Enum.KeyCode.LeftControl,
		},

		MainGunKey = Enum.KeyCode.One,
		CoaxGunKey = Enum.KeyCode.Two,
		CalculateDropKey = Enum.KeyCode.P,
		ReloadKey = Enum.KeyCode.R,
		SwitchShellsKey = Enum.KeyCode.V,
	},
}
