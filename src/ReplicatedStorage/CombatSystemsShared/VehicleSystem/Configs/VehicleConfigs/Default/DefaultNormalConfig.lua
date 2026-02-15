--!strict
--[[
	Default config for every tracked vehicle
]]

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DefaultConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleConfigs.Default.DefaultConfig)

local config = {
	ConfigType = "Normal",

	MovementConfigNormal = { -- Normal vehicles special
		WheelTurnAngle = 30, -- For how much degrees will be wheels rotated when steering vehicle
	},
}

return config :: typeof(config) & typeof(DefaultConfig)
