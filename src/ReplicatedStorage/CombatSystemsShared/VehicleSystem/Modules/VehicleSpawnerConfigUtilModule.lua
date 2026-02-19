--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleSpawnerConfigPath = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSpawnerConfig
local VehicleSpawnerConfigTemplate = require(VehicleSpawnerConfigPath.Config)
local TableInheritUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.TableInheritUtilModule)

-- FINALS
export type DefaultType = typeof(VehicleSpawnerConfigTemplate)
local spawnerConfigCache = {} :: { [BasePart]: DefaultType }

function module.parseSpawnerConfig(spawner: BasePart): DefaultType
	if not spawnerConfigCache[spawner] then
		local spawnerTransform = (spawner :: any) :: typeof(VehicleSpawnerConfigPath) -- for require line below not to be red
		local configModule = spawnerTransform:FindFirstChild("Config")
		assert(configModule and configModule:IsA("ModuleScript"), "Spawner config not found")
		local config = TableInheritUtil.inheritConfig({ require(configModule), VehicleSpawnerConfigTemplate }) :: typeof(VehicleSpawnerConfigTemplate) -- inheritance from default config template
		config.EnabledColor = spawner.Color
		spawnerConfigCache[spawner] = config
	end

	return spawnerConfigCache[spawner]
end

return module
