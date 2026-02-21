--[[
	Default config for every tracked vehicle
]]

return {
	ConfigType = "Tracked",

	PhysicalConfig = {
		Mass = 40,
	},

	MovementConfig = {
		MaxSpeed = 20,
		Acceleration = 0.45,
		Braking = 1,
		TorqueMultiplier = 250,
	},

	-- Tracked vehicle type special
	MovementConfigTracked = {
		-- Turn speed, closer to 1 = faster
		TurnRate = 4, 
	},

	WheelConfig = {
		PhysicalProperties = PhysicalProperties.new(
			20,
			1,
			1,
			50,
			50
		),
	},

	SuspensionConfig = {
		FreeLength = 3.05,
		LowerLimit = 0.5,
		StiffnessMultiplier = 90,
		DampingPercent = 10,
	},
}