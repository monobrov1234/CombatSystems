-- this config is a placeholder, its used in VehicleService - SpawnerService as a type template

return {
	Spawnables = {} :: { string }, -- list of vehicle names that this spawner can spawn
	Delay = 2, -- delay between spawning vehicles
	MaxUseDistance = 20, -- maximum distance that player is allowed to spawn vehicle from
	DisabledColor = Color3.new(1, 0.235294, 0), -- when spawner will enter delay, it will be that color
	EnabledColor = nil :: Color3?, -- set internally

	PositionOffset = Vector3.new(5, 0, 0), -- custom position offset from spawner local space
	RotationOffset = Vector3.new(0, -90, 0), -- custom rotation offset from spawner local space

	ForceDestroyObstruction = false, -- if true, will force destroy any vehicles in the spawner's way to spawn new vehicle
	-- if false - only vehicles that doesn't have a player driving them will be destroyed

	GroupWhitelist = nil :: { number }?, -- only players within these groups will be allowed to use the spawner, nil = disable
	TeamWhitelist = nil :: { string }? -- only players within these team names will be allowed to use the spawner, nil = disable 
}
