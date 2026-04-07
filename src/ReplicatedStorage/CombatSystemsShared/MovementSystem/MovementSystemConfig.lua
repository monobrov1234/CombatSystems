local assets = game:GetService("ReplicatedStorage").CombatSystemsShared.MovementSystem.Assets

return {
	-- Enable the movement system (sprint and crouch)
	Enabled = true,

	-- Keys
	SprintKey = Enum.KeyCode.F,
	CrouchKey = Enum.KeyCode.C,

	-- Animation links
	SprintAnimation = assets.SprintAnim,
	CrouchAnimation = assets.CrouchAnim,

	-- Behavior
	DefaultWalkSpeed = 16,
	SprintWalkSpeed = 24,
	CrouchWalkSpeed = 8,
	CrouchHipHeight = -1.1,
}
