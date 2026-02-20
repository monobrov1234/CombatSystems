--!strict

local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)

-- IMPORTS INTERNAL
local TurretViewController = require(PlayerScripts.CombatSystemsClient.TurretSystem.TurretController.TurretViewController)

-- ROBLOX OBJECTS

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretSeatScanner")
local cleaner = ConnectionCleaner.new()
local character: Model = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- STATE
local currentSeat: BasePart?

-- INTERNAL FUNCTIONS
function funcs.handleHumanoidSeated(active: boolean, seat: BasePart)
	if not active and currentSeat then
		log:debug("Handling dismount event on stationary turret")
		TurretViewController.setTurretView(nil, nil)
		currentSeat = nil
		VehicleSystemConfig.ShowToolsCallback(character, humanoid)
		ProximityPromptService.Enabled = true
		return
	end

	if not seat then
		return
	end
	local turretModel = seat.Parent :: Model?
	if not turretModel or not turretModel:IsA("Model") then
		return
	end
	if not TurretUtil.validateTurret(turretModel) then
		return
	end
	log:debug("Handling seated event on stationary turret {}", turretModel.Name)

	local customRayFilters: { Instance }?
	local vehicleInfo = VehicleUtil.findPlayerCurrentVehicle(player)
	if vehicleInfo then customRayFilters = { vehicleInfo.VehicleModel } :: { Instance } end

	TurretViewController.setTurretView(turretModel, customRayFilters)
	currentSeat = seat

	VehicleSystemConfig.HideToolsCallback(character, humanoid)
	ProximityPromptService.Enabled = false
end

function funcs.hookSeated()
	cleaner:add(humanoid.Seated:Connect(funcs.handleHumanoidSeated))
end

-- SUBSCRIPTIONS
funcs.hookSeated()

player.CharacterAdded:Connect(function(newCharacter)
	cleaner:disconnectAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	funcs.hookSeated()
end)
