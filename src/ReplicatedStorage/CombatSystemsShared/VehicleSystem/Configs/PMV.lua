return {
	ConfigType = "Normal",

	Description = "Utility Vehicle",
	MaxHealth = 10,

	PhysicalConfig = { -- vehicle physics and rig config
		Mass = 2, -- This value will be multiplied by 1000 to calculate total mass
	},

	MovementConfig = { -- Vehicle engine and movement config
		MaxSpeed = 55, -- Max speed of vehicle
		Acceleration = 0.35, -- How fast vehicle will reach max speed
		Braking = 0.35, -- How fast vehicle will decelerate
		TorqueMultiplier = 130, -- Mass will be multiplied by this value to calculate torque
	},

	WheelConfig = { -- Vehicle wheel physics
		PhysicalProperties = PhysicalProperties.new( -- Wheel physical properties
			5, -- Density, higher = heavier wheels
			1, -- Friction, max is 2
			0, -- Elasticity, higher = more bounce, but can conflict with suspension
			50, -- Friction weight, max is 100
			0 -- ElasticityWeight
		),
	},

	SuspensionConfig = { -- SpringConstraints configuration
		FreeLength = 1.5, -- Resting length of spring
		LowerLimit = 0, -- Final limit is calculated using FreeLength + LowerLimit
		StiffnessMultiplier = 400, -- Mass will be multiplied by this value to calculate stiffness 280
		DampingPercent = 5, -- Percent of stiffness to use as damping
	},
}
