return {
	ConfigType = "Tracked",

	MaxHealth = 100,
	Description = "Main Battle Tank",
	ProtectedDriver = true,
	HasDriverTurret = true,

	PhysicalConfig = { -- vehicle physics and rig config
		Mass = 50, -- This value will be multiplied by 1000 to calculate total mass
	},

	MovementConfig = { -- Vehicle engine and movement config
		MaxSpeed = 25, -- Max speed of vehicle
		Acceleration = 0.5, -- How fast vehicle will reach max speed
		Braking = 0.9, -- How fast vehicle will decelerate
		TorqueMultiplier = 200, -- Mass will be multiplied by this value to calculate torque
	},

	MovementConfigTracked = { -- Special for tracked vehicles
		TurnRate = 3.5, -- Turn speed, closer to 1 = faster
	},

	WheelConfig = { -- Vehicle wheel physics
		PhysicalProperties = PhysicalProperties.new( -- Wheel physical properties
			10, -- Density, higher = heavier wheels
			1, -- Friction, max is 2
			0, -- Elasticity, higher = more bounce, but can conflict with suspension
			50, -- Friction weight, max is 100
			0 -- ElasticityWeight
		),
	},

	SuspensionConfig = { -- SpringConstraints configuration
		FreeLength = 4.15, -- Resting length of spring
		LowerLimit = 0.5, -- Final limit is calculated using FreeLength + LowerLimit
		StiffnessMultiplier = 90, -- Mass will be multiplied by this value to calculate stiffness
		DampingPercent = 10, -- Percent of stiffness to use as damping
	},
}