local module = {}
module.__index = module

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableInheritUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.TableInheritUtilModule)

-- FINALS
local gunConfigs = ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunConfigs
local defaultConfig = require(gunConfigs.Default.DefaultConfig)
export type DefaultType = typeof(defaultConfig)

-- STATE
local inheritConfigs: { [string]: {} } = {}
for _, config in ipairs(gunConfigs:GetChildren()) do
	if not config:IsA("ModuleScript") then continue end
	assert(not inheritConfigs[config.Name])
	inheritConfigs[config.Name] = TableInheritUtil.inheritConfig({ require(config), defaultConfig })
end

function module.getConfig(gunName: string): DefaultType
	return inheritConfigs[gunName]
end

return module
