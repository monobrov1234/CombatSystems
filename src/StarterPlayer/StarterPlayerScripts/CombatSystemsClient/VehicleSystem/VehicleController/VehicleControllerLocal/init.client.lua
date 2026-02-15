--[[
	Abstract Vehicle Controller (Client-Side)
	
	This script handles how every vehicle drives client-side.
	It assigns the correct controller implementation based on the "VehicleType" attribute of vehicle seat part.
	
	TODO: documentation about vehicle rig
]]

local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleanerModule)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)
local TurretViewController = require(player.PlayerScripts.CombatSystemsClient.GunSystem.TurretViewController.TurretViewControllerModule)
local MovementController = require(player.PlayerScripts.CombatSystemsClient.MovementSystem.MovementControllerModule)

-- IMPORTS INTERNAL
local GuiController = require(script.GuiControllerModule)

-- ROBLOX OBJECTS
local character = player.Character or player.CharacterAdded:Wait()
local rootPart: BasePart = character:WaitForChild("HumanoidRootPart")
local humanoid: Humanoid = character:WaitForChild("Humanoid")

local ownershipRemote = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.ClientToServer.SetVehicleOwnership

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleController")
local cleaner = ConnectionCleaner.new()

type VehicleController = {
	handleSeated: (vehicleInfo: VehicleUtil.VehicleInfo) -> (),
	driveLoop: (deltaTime: number) -> (),
	handleDismount: () -> (),
}
local controllerMapping: { [string]: VehicleController } = {
	["Normal"] = require(script.Parent.Implementations.NormalVehicleControllerModule),
	["Tracked"] = require(script.Parent.Implementations.TrackedVehicleControllerModule),
}

local vehicleInfo: VehicleUtil.VehicleInfo
local currentSeat = nil :: Seat | VehicleSeat
local vehicleController: VehicleController
local driveLoopConnection: RBXScriptConnection
local turretModel: Model?

function funcs.handleHumanoidSeated(active: boolean, seat: Seat | VehicleSeat)
	if not active and vehicleInfo then
		log:debug("Dismount called")
		funcs.dismountPlayer()
		if vehicleController then vehicleController.handleDismount() end
		funcs.clearVehicle()
		return
	end

	if not seat or not seat.Parent then return end
	if not VehicleUtil.validateVehicle(seat.Parent) then return end
	log:debug("Handling seated event on seat {}", seat.Name)

	local info = VehicleUtil.parseVehicleInfo(seat.Parent)
	GuiController.enableGui(info)

	if seat == info.DriverSeat then
		log:debug("Is a driver seat")
		local controller = controllerMapping[info.VehicleConfig.ConfigType]
		assert(controller, "No vehicle controller implementation found for vehicle type")

		vehicleController = controller
		vehicleController.handleSeated(info)

		driveLoopConnection = RunService.PostSimulation:Connect(vehicleController.driveLoop)
		ownershipRemote:FireServer()
		workspace.CurrentCamera.CameraSubject = info.Camera

		if info.VehicleConfig.HasDriverTurret then
			-- find driver gunner turret (turret without any seats)
			local turrets: { Model } = TurretUtil.findDescendantTurrets(info.VehicleModel)
			for _, turret: Model in ipairs(turrets) do
				if TurretUtil.findTurretSeat(turret) then continue end -- is a stationary turret, skip
				turretModel = turret
				TurretViewController.setTurretView(turret, { info.VehicleModel })
				break
			end

			assert(true, "Vehicle config have HasDriverTurret set to true, but no driver turret has been found")
		end

		VehicleSystemConfig.HideToolsCallback(character, humanoid)
	end

	vehicleInfo = info
	currentSeat = seat
	ProximityPromptService.Enabled = false
	log:debug("State set successfuly")
end

function funcs.clearVehicle()
	log:debug("Clearing state...")
	GuiController.disableGui()

	if currentSeat == vehicleInfo.DriverSeat then
		log:debug("Clearing driver seat state...")
		if turretModel then
			TurretViewController.setTurretView(nil, nil)
			turretModel = nil
		end

		driveLoopConnection:Disconnect()
		VehicleSystemConfig.ShowToolsCallback(character, humanoid)
	end

	vehicleInfo = nil
	ProximityPromptService.Enabled = true
	log:debug("State cleared successfully")
end

function funcs.dismountPlayer()
	local dismountPart: BasePart
	if currentSeat == vehicleInfo.DriverSeat then
		dismountPart = vehicleInfo.DismountPart
	else
		dismountPart = (currentSeat :: any):FindFirstChild("DismountPart")
	end
	if dismountPart and dismountPart.Parent then
		rootPart:PivotTo(dismountPart.CFrame)
		log:debug("Pivoted to the dismount part successfully")
	else
		log:debug("Dismount part not found!")
	end

	MovementController.setSprinting(false)
end

local function connect()
	cleaner:add(humanoid.Seated:Connect(funcs.handleHumanoidSeated))
end
connect()

player.CharacterAdded:Connect(function(newCharacter)
	cleaner:disconnectAll()
	if vehicleInfo then funcs.clearVehicle() end
	character = newCharacter
	rootPart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")
	connect()
end)
