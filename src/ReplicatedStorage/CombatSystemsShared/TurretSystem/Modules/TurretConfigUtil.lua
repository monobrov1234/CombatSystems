local module = {}
module.__index = module

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableInheritUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.TableInheritUtil)

-- FINALS
local turretConfigs = ReplicatedStorage.CombatSystemsShared.TurretSystem.Configs
local defaultConfig = require(turretConfigs.Default.DefaultConfig)
export type DefaultType = typeof(defaultConfig)

-- STATE
local inheritConfigs: { [string]: {} } = {}
for _, config in ipairs(turretConfigs:GetChildren()) do
	if not config:IsA("ModuleScript") then continue end
	inheritConfigs[config.Name] = TableInheritUtil.inheritConfig({ require(config), defaultConfig })
end

function module.getConfig(turretName: string): DefaultType
	return inheritConfigs[turretName] :: DefaultType
end

return module
