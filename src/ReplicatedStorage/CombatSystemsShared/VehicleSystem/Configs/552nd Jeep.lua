return {
	ConfigType = "Normal",

	Description = "Military Police Vehicle",
	MaxHealth = 20,

	PhysicalConfig = {
		Mass = 2,
	},

	MovementConfig = {
		MaxSpeed = 60,
		Acceleration = 0.4,
		Braking = 0.4,
		TorqueMultiplier = 130,
	},

	WheelConfig = {
		PhysicalProperties = PhysicalProperties.new(11, 1, 0, 50, 0),
	},

	SuspensionConfig = {
		FreeLength = 1.3,
		LowerLimit = 0,
		StiffnessMultiplier = 250,
		DampingPercent = 10,
	},
}
