return {
	ConfigType = "Normal",
	Description = "Utility Vehicle",
	MaxHealth = 20,

	PhysicalConfig = {
		Mass = 10,
	},

	MovementConfig = {
		MaxSpeed = 50,
		Acceleration = 0.15,
		Braking = 0.5,
		TorqueMultiplier = 130,
	},

	WheelConfig = {
		PhysicalProperties = PhysicalProperties.new(7, 1, 1, 50, 0),
	},

	SuspensionConfig = {
		FreeLength = 2,
		LowerLimit = 0.1,
		StiffnessMultiplier = 160,
		DampingPercent = 10,
	},
}