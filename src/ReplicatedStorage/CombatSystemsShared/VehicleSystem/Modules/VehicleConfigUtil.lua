--!strict

local module = {}
module.__index = module

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableInheritUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.TableInheritUtil)

-- ROBLOX OBJECTS
local configsFolder = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs
local defaultConfigs = configsFolder.Default
local defaultConfigScript = defaultConfigs.DefaultConfig

-- FINALS
local defaultConfig = require(defaultConfigScript)
export type DefaultType = typeof(defaultConfig)

-- this table is used to cache vehicle type specific configs, like DefaultNormal config
-- indexed by ConfigType value of vehicle config (e.g "Normal" or "Tracked")
local typeConfigs = {} :: { [string]: DefaultType }
for _, child: ModuleScript in ipairs(defaultConfigs:GetChildren()) do
	if child == defaultConfigScript then continue end
	assert(child:IsA("ModuleScript"))
	local config = require(child) :: DefaultType
	typeConfigs[config.ConfigType] = config
end

-- this table is used to cache inherited version of every vehicle config using TableInheritUtil.inheritConfig
-- indexed by vehicle name
local configs = {} :: { [string]: DefaultType }
for _, descendant: Instance in ipairs(configsFolder:GetDescendants()) do
	if not descendant:IsA("ModuleScript") then continue end
	if descendant:IsDescendantOf(defaultConfigs) then continue end

	local config = require(descendant) :: DefaultType
	local typeConfig: DefaultType = typeConfigs[config.ConfigType]
	assert(typeConfig, "Invalid ConfigType for vehicle config " .. descendant.Name)

	configs[descendant.Name] = TableInheritUtil.inheritConfig({ config, typeConfig, defaultConfig }) :: DefaultType
end

function module.getConfig(vehicle: Model): DefaultType?
	return configs[vehicle.Name]
end

return module
