return {
	ConfigType = "Normal",
	Description = "Firefighting Vehicle",
	MaxHealth = 20,

	PhysicalConfig = {
		Mass = 10,
	},

	MovementConfig = {
		MaxSpeed = 50,
		Acceleration = 0.3,
		Braking = 0.5,
		TorqueMultiplier = 130,
	},

	WheelConfig = {
		PhysicalProperties = PhysicalProperties.new(11, 1, 1, 50, 0),
	},

	SuspensionConfig = {
		FreeLength = 1.4,
		LowerLimit = 0.1,
		StiffnessMultiplier = 300,
		DampingPercent = 9,
	},
}