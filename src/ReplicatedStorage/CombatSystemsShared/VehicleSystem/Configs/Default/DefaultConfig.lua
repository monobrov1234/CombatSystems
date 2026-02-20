--[[
	Default config for every vehicle type
]]

return {
	ConfigType = "" :: string, -- set internally, changing this wont do anything

	MaxHealth = 20, -- vehicle max health TODO
	Description = "Generic vehicle", -- for gui
	ProtectedDriver = false, -- if true, driver will be in god mode as long as he's sitting in the vehicle
	ProtectedPassenger = false, -- if true, passenger will be in god mode as long as he's sitting in the vehicle
	HasDriverTurret = false, -- if vehicle have turret that can be controlled by driver - set it to true

	SeatConfig = {
		DriverPromptHoldDuration = 0.5, -- proximity prompt hold duration
		DriverPromptDistance = 20, -- proximity prompt activation distance
		PassengerPromptHoldDuration = 0.5,
		PassengerPromptDistance = 15,

		DriverGroupWhitelist = nil :: { number }?, -- driver will be required to be in any of these groups to drive the vehicle
		DriverTeamWhitelist = nil :: { string }?, -- driver will be required to be in any of these teams to drive the vehicle
		PassengerGroupWhitelist = nil :: { number }?, -- passenger will be required to be in any of these groups to enter the vehicle
		PassengerTeamWhitelist = nil :: { string }?, -- passenger will be required to be in any of these teams to enter the vehicle
	},

	DecorConfig = {
		SoundsConfig = {
			Enter = script.Start :: Sound?, -- will be played when you will enter the vehicle through driver seat proximity prompt
			Dismount = script.Stop :: Sound?, -- will be player when you will leave the vehicle (if you were driver)
			EngineIdle = script.Active :: Sound?, -- will be playing continuously until you will leave the vehicle
			EngineMove = script.Move :: Sound?, -- will be playing when you will press WASD to move the vehicle
		},
	},

	PhysicalConfig = { -- vehicle physics and rig config
		Mass = 1, -- This value will be multiplied by 1000 to calculate total mass
		DefaultPhysicalProperties = PhysicalProperties.new(0.0001, 1, 0, 1, 0), -- Normally only one part will have mass, this is used to give the rest of the parts some weight to prevent bugs
		AutoRig = true, -- If true, will auto weld and rig the vehicle, set to false if you want to make custom rig
		AutoRigTurrets = true, -- If true, will auto rig and weld all turrets in the vehicle when its spawned
	},

	MovementConfig = { -- Vehicle engine config
		MaxSpeed = 40, -- Max speed of vehicle
		Acceleration = 0.5, -- How fast vehicle will reach max speed
		Braking = 1, -- How fast vehicle will decelerate
		TorqueMultiplier = 130, -- Mass will be multiplied by this value to calculate torque
	},

	WheelConfig = { -- Vehicle wheel physics
		PhysicalProperties = PhysicalProperties.new( -- Wheel physical properties
			2, -- Density, higher = heavier wheels
			1, -- Friction, max is 2
			0, -- Elasticity, higher = more bounce, but can conflict with suspension
			50, -- Friction weight, max is 100
			0 -- ElasticityWeight
		),
	},

	SuspensionConfig = { -- SpringConstraints configuration
		FreeLength = 1.5, -- Resting length of spring
		LowerLimit = 1, -- Final limit is calculated using FreeLength + LowerLimit
		StiffnessMultiplier = 25, -- Mass will be multiplied by this value to calculate stiffness
		DampingPercent = 5, -- Percent of stiffness to use as damping
	},
}
