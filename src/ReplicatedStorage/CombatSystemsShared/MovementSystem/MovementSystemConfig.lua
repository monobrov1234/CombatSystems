local assets = game:GetService("ReplicatedStorage").CombatSystemsShared.MovementSystem.Assets

return {
	-- Enable the movement system (sprint and crouch)
	Enabled = true,

	-- Keys
	SprintKey = Enum.KeyCode.F,
	CrouchKey = Enum.KeyCode.C,

	-- Animation links, set to nil if you don't want custom animations
	SprintAnimation = assets.SprintAnim :: Animation?,
	CrouchAnimation = assets.CrouchAnim :: Animation?,

	-- Behavior
	DefaultWalkSpeed = 16,
	SprintWalkSpeed = 24,
	CrouchWalkSpeed = 8,
	CrouchHipHeight = -1.1,
}
