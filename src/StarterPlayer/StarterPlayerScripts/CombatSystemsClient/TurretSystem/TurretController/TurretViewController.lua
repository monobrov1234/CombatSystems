--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- IMPORTS INTERNAL
local CursorController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.ClientFX.CursorController)

-- ROBLOX OBJECTS
-- S->C
local setTurretStateRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ServerToClient.SetState

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretViewController")

-- STATE
local turretInfo: TurretUtil.TurretInfo?
local turretState: TurretUtil.TurretStateInfo?

-- PUBLIC EVENTS
module.TurretViewSet = Signal.new()
module.TurretViewCleared = Signal.new()
module.TurretStateChanged = Signal.new()

-- PUBLIC API
function module.setTurretView(turretModel: Model?, customRayFilters: { Instance }?)
	if not turretModel then
		funcs.clearTurretView()
		return
	end

	local character: Model? = player.Character
	assert(character)
	turretInfo = TurretUtil.parseTurretInfo(turretModel)
	assert(turretInfo)

	module.TurretViewSet:fire(turretInfo, customRayFilters)
	log:debug("Local turret view set")
end

function module.getCurrentTurretInfo(): TurretUtil.TurretInfo?
	return turretInfo
end

function module.getCurrentTurretState(): TurretUtil.TurretStateInfo?
	return turretState
end

-- INTERNAL FUNCTIONS
function funcs.clearTurretView()
	if not turretInfo then return end
	module.TurretViewCleared:fire()
	turretInfo = nil
	turretState = nil
	CursorController.disableCursor()
end

function funcs.handleSetTurretState(newTurretState: TurretUtil.TurretStateInfo)
	turretState = newTurretState
	module.TurretStateChanged:fire(newTurretState)
end

-- SUBSCRIPTIONS
player.CharacterAdded:Connect(function()
	if turretInfo then
		funcs.clearTurretView()
	end
end)
setTurretStateRemote.OnClientEvent:Connect(funcs.handleSetTurretState)

return module
