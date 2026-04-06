--[[
	Default configuration for every vehicle type
]]

return {
	-- Internal config identifier. Automatically set by the system. Do not change.
	ConfigType = "" :: string,

	-- Maximum health of the vehicle
	MaxHealth = 20,
	-- Short description shown in the vehicle HUD
	Description = "Generic vehicle",
	-- Makes the driver invulnerable while seated in the vehicle
	ProtectedDriver = false,
	-- Makes passengers invulnerable while seated in the vehicle
	ProtectedPassenger = false,

	-- Set to true if the vehicle has a turret without any seats, and you want the driver to control it
	-- Will error if the turret cannot be found
	HasDriverTurret = false,

	SeatConfig = {
		-- Hold time (seconds) required to enter the driver seat via ProximityPrompt
		DriverPromptHoldDuration = 0.5,
		-- Maximum distance (studs) at which the driver prompt appears
		DriverPromptDistance = 20,

		-- Hold time (seconds) required to enter as passenger
		PassengerPromptHoldDuration = 0.5,
		-- Maximum distance (studs) at which the passenger prompt appears
		PassengerPromptDistance = 15,

		-- Player must be in at least one of these groups to drive (nil = no restriction)
		DriverGroupWhitelist = nil :: { number }?,
		-- Player must be in one of these teams to drive (nil = no restriction)
		DriverTeamWhitelist = nil :: { string }?,

		-- Player must be in at least one of these groups to ride as passenger
		PassengerGroupWhitelist = nil :: { number }?,
		-- Player must be in one of these teams to ride as passenger
		PassengerTeamWhitelist = nil :: { string }?,
	},

	DecorConfig = {
		SoundsConfig = {
			-- Sound played when entering the driver seat
			Enter = script.Start :: Sound?,
			-- Sound played when dismounting from the vehicle
			Dismount = script.Stop :: Sound?,
			-- Looping idle engine sound
			EngineIdle = script.Active :: Sound?,
			-- Looping sound played while the vehicle is moving
			EngineMove = script.Move :: Sound?,
		},
	},

	PhysicalConfig = {
		-- Mass multiplier. Final vehicle mass = Mass × 1000
		Mass = 1,
		-- Physical properties applied to all parts, do not increase density much here
		DefaultPhysicalProperties = PhysicalProperties.new(0.0001, 1, 0, 1, 0),
		-- Automatically weld and rig the main vehicle model on spawn
		AutoRig = true,
		-- Automatically rig all turrets mounted on the vehicle on spawn
		AutoRigTurrets = true,
	},

	MovementConfig = {
		-- Maximum vehicle speed in studs per second
		MaxSpeed = 40,
		-- Acceleration strength (higher = faster)
		Acceleration = 0.5,
		-- Braking strength (higher = faster)
		Braking = 1,
		-- Torque multiplier (Torque formula = Mass * TorqueMultiplier) TODO: rework
		TorqueMultiplier = 130,
	},

	WheelConfig = {
		-- Physical properties for all wheels
		PhysicalProperties = PhysicalProperties.new(
			2,   -- Density (0 to 100)
			1,   -- Friction
			0,   -- Elasticity
			50,  -- FrictionWeight
			0    -- ElasticityWeight
		),
	},

	SuspensionConfig = {
		-- Natural resting length of the suspension spring (studs)
		FreeLength = 1.5,
		-- How much the suspension can extend below FreeLength
		LowerLimit = 1,
		-- Suspension stiffness multiplier (Stiffness formula = (Mass / WheelCount) * StiffnessMultiplier)
		StiffnessMultiplier = 25,
		-- Damping as a percentage of the stiffness value
		DampingPercent = 5,
		-- Max spring force
		MaxForce = math.huge
	},
}