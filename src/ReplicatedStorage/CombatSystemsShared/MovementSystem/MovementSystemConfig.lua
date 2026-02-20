return {
	-- Enable the movement system (sprint and crouch)
	Enabled = true,

	-- Keys
	SprintKey = Enum.KeyCode.F,
	CrouchKey = Enum.KeyCode.C,

	-- Animation links
	SprintAnimation = script.Sprint,
	CrouchAnimation = script.Crouch,

	-- Behavior
	DefaultWalkSpeed = 16,
	SprintWalkSpeed = 24,
	CrouchWalkSpeed = 8,
	CrouchHipHeight = -1.1,
}
