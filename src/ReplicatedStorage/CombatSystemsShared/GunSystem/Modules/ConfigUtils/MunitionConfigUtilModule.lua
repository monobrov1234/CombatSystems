local module = {}
module.__index = module

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableInheritUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.TableInheritUtilModule)

-- FINALS
local munitionConfigs = ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.MunitionConfigs
local defaultConfig = require(munitionConfigs.Default.DefaultConfig)
export type DefaultType = typeof(defaultConfig)

-- STATE
local inheritConfigs: { [string]: {} } = {}
for _, config: Instance in ipairs(munitionConfigs:GetDescendants()) do
	if not config:IsA("ModuleScript") then continue end
	if config:FindFirstAncestorOfClass("ModuleScript") then continue end -- if its script that is parented to a module script, we ignore it
	if config == defaultConfig then continue end
	assert(not inheritConfigs[config.Name])
	inheritConfigs[config.Name] = TableInheritUtil.inheritConfig({ require(config), defaultConfig })
	inheritConfigs[config.Name].MunitionName = config.Name
end

function module.getConfig(munitionName: string): DefaultType
	return inheritConfigs[munitionName]
end

function module.getDefaultConfig()
	return defaultConfig
end

return module
