--!strict
--[[
	Default config for every tracked vehicle
]]

local DefaultConfig = require(game:GetService("ReplicatedStorage").CombatSystemsShared.VehicleSystem.Configs.VehicleConfigs.Default.DefaultConfig)

local config = {
	ConfigType = "Tracked",

	PhysicalConfig = { -- vehicle physics and rig config
		Mass = 40, -- This value will be multiplied by 1000 to calculate total mass
	},

	MovementConfig = { -- Vehicle engine and movement config
		MaxSpeed = 20, -- Max speed of vehicle
		Acceleration = 0.45, -- How fast vehicle will reach max speed
		Braking = 1, -- How fast vehicle will decelerate
		TorqueMultiplier = 250, -- Mass will be multiplied by this value to calculate torque
	},

	MovementConfigTracked = { -- Special for tracked vehicles
		TurnRate = 4, -- Turn speed, closer to 1 = faster
	},

	WheelConfig = { -- Vehicle wheel physics
		PhysicalProperties = PhysicalProperties.new( -- Wheel physical properties
			20, -- Density, higher = heavier wheels
			1, -- Friction, max is 2
			1, -- Elasticity, higher = more bounce, but can conflict with suspension
			50, -- Friction weight, max is 100
			50 -- ElasticityWeight
		),
	},

	SuspensionConfig = { -- SpringConstraints configuration
		FreeLength = 3.05, -- Resting length of spring
		LowerLimit = 0.5, -- Final limit is calculated using FreeLength + LowerLimit
		StiffnessMultiplier = 90, -- Mass will be multiplied by this value to calculate stiffness
		DampingPercent = 10, -- Percent of stiffness to use as damping
	},
}

return config :: typeof(config) & typeof(DefaultConfig)
