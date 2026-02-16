--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

-- ROBLOX OBJECTS
-- S->C
local setTurretStateRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ServerToClient.SetState

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretStateService")

-- wrapper around turretInfo with dynamically resolved raycastBlacklist for custom turret mounting implementations (e.g vehicle system)
export type PlayerTurretInfo = {
	turretInfo: TurretUtil.TurretInfo,
	raycastBlacklist: { Instance }?,
}

-- contains own turret state for each turret on the map
local turretStateTable = {} :: { [Model]: TurretUtil.TurretStateInfo }

-- contains turret that the player is currently controlling, and resolved raycast blacklist for the turret
local playerTurrets = {} :: { [Player]: PlayerTurretInfo? }

-- PUBLIC API

-- used by turret view initializers
function module.setPlayerTurretView(player: Player, turretInfo: TurretUtil.TurretInfo?, raycastBlacklist: { Instance }?)
	if not turretInfo then
		playerTurrets[player] = nil
		log:debug("Player {} server turret info cleared", player.Name)
		return
	end

	local stateInfo: TurretUtil.TurretStateInfo = module.getTurretState(turretInfo) or funcs.setupStateFor(turretInfo)
	stateInfo.UsingMainGun = true -- by default erase coax state

	playerTurrets[player] = {
		turretInfo = turretInfo,
		raycastBlacklist = raycastBlacklist,
	} :: PlayerTurretInfo

	setTurretStateRemote:FireClient(player, stateInfo)

	log:debug("Player {} server turret info set to {}", player.Name, turretInfo.TurretModel.Name)
end

function module.getPlayerCurrentTurret(player: Player): TurretUtil.TurretInfo?
	local playerTurretInfo = playerTurrets[player]
	return playerTurretInfo and playerTurretInfo.turretInfo
end

function module.getPlayerRaycastBlacklist(player: Player): { Instance }?
	local playerTurretInfo = playerTurrets[player]
	return playerTurretInfo and playerTurretInfo.raycastBlacklist
end

function module.getTurretState(turretInfo: TurretUtil.TurretInfo): TurretUtil.TurretStateInfo?
	return turretStateTable[turretInfo.TurretModel]
end

-- INTERNAL FUNCTIONS

-- sets up server state for a turret, called when someone interacts with it first time
function funcs.setupStateFor(turretInfo: TurretUtil.TurretInfo): TurretUtil.TurretStateInfo
	local turretModel: Model = turretInfo.TurretModel
	local entry: TurretUtil.TurretStateInfo? = turretStateTable[turretModel]
	assert(entry == nil)

	local gunConfig = turretInfo.TurretConfig.GunConfig
	local clipSizeStorage = {} :: { [string]: number }
	local munitionStorage = {} :: { [string]: number }
	for _, data in ipairs(gunConfig.AmmoTypes) do
		clipSizeStorage[data.name] = gunConfig.ClipSize
		munitionStorage[data.name] = data.stored
	end

	entry = {
		SelectedMunition = gunConfig.AmmoTypes[1].name,
		ClipSizeStorage = clipSizeStorage,
		MunitionStorage = munitionStorage,
		UsingMainGun = false,
		CoaxClipSize = gunConfig.CoaxConfig.ClipSize,
		CoaxAmmoSize = gunConfig.CoaxConfig.AmmoSize,
	}
	turretStateTable[turretModel] = entry :: TurretUtil.TurretStateInfo

	-- recheck memory leaks
	-- auto remove from global storage if the turret is destroyed
	turretModel.Destroying:Once(function()
		log:debug("Turret {} destroyed, removing its state", turretModel.Name)
		turretStateTable[turretModel] = nil
	end)

	return entry :: TurretUtil.TurretStateInfo
end

-- playerTurrets table clean logic
Players.PlayerRemoving:Connect(function(player: Player)
	playerTurrets[player] = nil
end)

return module