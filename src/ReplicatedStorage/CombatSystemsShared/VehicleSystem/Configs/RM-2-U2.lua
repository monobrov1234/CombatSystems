return {
	ConfigType = "Tracked",

	MaxHealth = 80,
	Description = "Medium Tank",
	ProtectedDriver = true,
	HasDriverTurret = true,

	PhysicalConfig = {
		Mass = 40,
	},

	MovementConfig = {
		MaxSpeed = 20,
		Acceleration = 0.45,
		Braking = 0.9,
		TorqueMultiplier = 200,
	},

	MovementConfigTracked = {
		TurnRate = 3.7,
	},

	WheelConfig = {
		PhysicalProperties = PhysicalProperties.new(10, 1, 1, 50, 50),
	},

	SuspensionConfig = {
		FreeLength = 4.15,
		LowerLimit = 0.5,
		StiffnessMultiplier = 61,
		DampingPercent = 10,
	},
}
