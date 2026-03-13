return {
	Tag = "GunControl", -- gun tool should have this tag to be recognized as a compatible gun
	RigGunsTag = "RigGuns", -- all instances with this tag will have their descendant guns rigged on startup

	-- bindings
	KeyBindings = {
		ReloadKey = Enum.KeyCode.R,
		ZoomKey = Enum.KeyCode.Q,
		PatrolKey = Enum.KeyCode.T,
	},
}
