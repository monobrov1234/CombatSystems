return {
	ConfigType = "Normal",

	Description = "Utility Vehicle",
	MaxHealth = 10,

	PhysicalConfig = {
		Mass = 2,
	},

	MovementConfig = {
		MaxSpeed = 55,
		Acceleration = 0.35,
		Braking = 0.35,
		TorqueMultiplier = 130,
	},

	WheelConfig = {
		PhysicalProperties = PhysicalProperties.new(5, 1, 0, 50, 0),
	},

	SuspensionConfig = {
		FreeLength = 1.5,
		LowerLimit = 0,
		StiffnessMultiplier = 400,
		DampingPercent = 5,
	},
}
