return {
	ConfigType = "Normal",

	MaxHealth = 80,
	Description = "Armored Car",
	ProtectedDriver = true,
	HasDriverTurret = true,

	PhysicalConfig = {
		Mass = 10,
	},

	MovementConfig = {
		MaxSpeed = 60,
		Acceleration = 0.5,
		Braking = 1,
		TorqueMultiplier = 130,
	},

	WheelConfig = {
		PhysicalProperties = PhysicalProperties.new(20, 1, 0, 50, 0),
	},

	SuspensionConfig = {
		FreeLength = 2,
		LowerLimit = 0,
		StiffnessMultiplier = 170,
		DampingPercent = 10,
	},
}
