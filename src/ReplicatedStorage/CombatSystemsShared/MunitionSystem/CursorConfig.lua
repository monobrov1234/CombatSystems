return {
	Cursors = { -- list of available cursors
		8229322464, -- default +
		11637362159,
		11637367551,
		11637386373,
	},
	DefaultCursor = 1, -- default cursor index to select from the list

	FadeTime = 0.8, -- time of transition between default and enemy/friendly cursor color when hovered
	DefaultColor = Color3.new(1, 1, 1), -- color when the cursor isn't hovering over any player
	EnemyColor = Color3.fromRGB(255, 80, 80), -- color when the cursor is over an enemy
	FriendlyColor = Color3.fromRGB(94, 255, 69), -- color when the cursor is over an ally

	ChangeMenuKey = Enum.KeyCode.N, -- on press, the cursor change menu will open
}
