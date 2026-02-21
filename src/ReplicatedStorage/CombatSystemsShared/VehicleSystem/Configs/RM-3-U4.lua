return {
	ConfigType = "Tracked",

	MaxHealth = 100,
	Description = "Main Battle Tank",
	ProtectedDriver = true,
	HasDriverTurret = true,

	PhysicalConfig = {
		Mass = 50,
	},

	MovementConfig = {
		MaxSpeed = 25,
		Acceleration = 0.5,
		Braking = 0.9,
		TorqueMultiplier = 200,
	},

	MovementConfigTracked = {
		TurnRate = 3.5,
	},

	WheelConfig = {
		PhysicalProperties = PhysicalProperties.new(10, 1, 0, 50, 0),
	},

	SuspensionConfig = {
		FreeLength = 4.15,
		LowerLimit = 0.5,
		StiffnessMultiplier = 90,
		DampingPercent = 10,
	},
}