--!strict

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleanerModule)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local TurretViewController = require(script.Parent.TurretViewControllerModule)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretSeatScanner")
local cleaner = ConnectionCleaner.new()
local player = Players.LocalPlayer :: Player
local character: Model = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- STATE
local currentSeat: BasePart?

local function handleHumanoidSeated(active: boolean, seat: BasePart)
	if not active and currentSeat then
		log:debug("Handling dismount event on stationary turret")
		TurretViewController.setTurretView(nil, nil)
		currentSeat = nil
		VehicleSystemConfig.ShowToolsCallback(character, humanoid)
		ProximityPromptService.Enabled = true
		return
	end

	if not seat then return end
	local turretModel = seat.Parent :: Model?
	if not turretModel or not turretModel:IsA("Model") then return end
	if not TurretUtil.validateTurret(turretModel) then return end
	log:debug("Handling seated event on stationary turret {}", turretModel.Name)

	-- if this turret is mounted on a vehicle, ignore that vehicle in ray params
	local customRayFilters: { Instance }?
	local vehicleInfo = VehicleUtil.findPlayerCurrentVehicle(player)
	if vehicleInfo then customRayFilters = { vehicleInfo.VehicleModel } :: { Instance } end

	TurretViewController.setTurretView(turretModel, customRayFilters)
	currentSeat = seat

	VehicleSystemConfig.HideToolsCallback(character, humanoid)
	ProximityPromptService.Enabled = false
end

local function hookSeated()
	cleaner:add(humanoid.Seated:Connect(handleHumanoidSeated))
end
hookSeated()

player.CharacterAdded:Connect(function(newCharacter)
	cleaner:disconnectAll()
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	hookSeated()
end)
