--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)

-- IMPORTS INTERNAL
local VehicleSpawnService = require(script.Parent.VehicleSpawnService)

-- ROBLOX OBJECTS
-- C->S
local adminDeleteRemote = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.AdminTools.ClientToServer.DeleteVehicle
local adminSpawnRemote = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.AdminTools.ClientToServer.SpawnVehicle

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleAdminService")

-- INTERNAL FUNCTIONS
function funcs.handleAdminVehicleSpawn(player: Player, vehicleName: string, spawnCframe: CFrame)
	assert(typeof(vehicleName) == "string" and typeof(spawnCframe) == "CFrame")
	log:debug("Handling admin vehicle spawn event for player {}", player.Name)

	local character: Model? = player.Character
	assert(character)
	local currentTool = character:FindFirstChildOfClass("Tool")
	assert(currentTool and currentTool:HasTag(VehicleSystemConfig.VehicleSpawnerToolTag))

	local vehicle = VehicleSystemConfig.Folder:FindFirstChild(vehicleName) :: Model?
	assert(vehicle)

	VehicleSpawnService.requestSpawn(vehicle, spawnCframe)
end

function funcs.handleAdminVehicleDelete(player: Player, vehicle: Model)
	assert(typeof(vehicle) == "Instance")
	assert(vehicle:IsA("Model"))
	log:debug("Handling admin vehicle delete event for player {}", player.Name)

	local character: Model? = player.Character
	assert(character)
	local currentTool = character:FindFirstChildOfClass("Tool")
	assert(currentTool and currentTool:HasTag(VehicleSystemConfig.VehicleDeleterToolTag))

	assert(VehicleUtil.validateVehicle(vehicle))
	vehicle:Destroy()
end

-- SUBSCRIPTIONS
adminSpawnRemote.OnServerEvent:Connect(funcs.handleAdminVehicleSpawn)
adminDeleteRemote.OnServerEvent:Connect(funcs.handleAdminVehicleDelete)

return module
