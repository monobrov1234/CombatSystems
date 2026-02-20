return {
	ConfigType = "Normal",

	MaxHealth = 80,
	Description = "Armored Car",
	ProtectedDriver = true,
	HasDriverTurret = true,

	PhysicalConfig = { -- vehicle physics and rig config
		Mass = 10, -- This value will be multiplied by 1000 to calculate total mass
	},

	MovementConfig = { -- Vehicle engine and movement config
		MaxSpeed = 60, -- Max speed of vehicle
		Acceleration = 0.5, -- How fast vehicle will reach max speed
		Braking = 1, -- How fast vehicle will decelerate
		TorqueMultiplier = 130, -- Mass will be multiplied by this value to calculate torque
	},

	WheelConfig = { -- Vehicle wheel physics
		PhysicalProperties = PhysicalProperties.new( -- Wheel physical properties
			20, -- Density, higher = heavier wheels
			1, -- Friction, max is 2
			0, -- Elasticity, higher = more bounce, but can conflict with suspension
			50, -- Friction weight, max is 100
			0 -- ElasticityWeight
		),
	},

	SuspensionConfig = { -- SpringConstraints configuration
		FreeLength = 2, -- Resting length of spring
		LowerLimit = 0, -- Final limit is calculated using FreeLength + LowerLimit
		StiffnessMultiplier = 170, -- Mass will be multiplied by this value to calculate stiffness 280
		DampingPercent = 10, -- Percent of stiffness to use as damping
	},
}
