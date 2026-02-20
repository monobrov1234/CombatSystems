--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local TurretSystemConfig = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.TurretSystemConfig)
local CursorController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.ClientFX.CursorController)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)

-- IMPORTS INTERNAL
local TurretViewController = require(script.Parent.TurretViewController)

-- FINALS
local cleaner = ConnectionCleaner.new()
local SENSIVITY_DIVIDER = 2

-- STATE
local turretInfo: TurretUtil.TurretInfo?

local initialFOV: number?
local initialSens: number?
local firstPersonMode = false
local firstPersonStep = 1

-- INTERNAL FUNCTIONS
function funcs.handleTurretViewSet(newTurretInfo: TurretUtil.TurretInfo, customRayFilters: { Instance }?)
	turretInfo = newTurretInfo
end

function funcs.handleTurretViewCleared()
	cleaner:disconnectAll()
	if firstPersonMode then
		funcs.exitFirstPerson()
		firstPersonMode = false
	end
	firstPersonStep = 1
	turretInfo = nil
end

function funcs.handleInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not turretInfo then return end

	local bindings = TurretSystemConfig.KeyBindings.FirstPersonMode
	if input.KeyCode == bindings.ToggleKey then
		funcs.toggleFirstPerson()
	elseif input.KeyCode == bindings.ZoomInKey then
		funcs.zoomInFirstPerson()
	elseif input.KeyCode == bindings.ZoomOutKey then
		funcs.zoomOutFirstPerson()
	end
end

function funcs.updateFirstPersonSensivity()
	assert(initialFOV and initialSens)
	local currentFov = workspace.CurrentCamera.FieldOfView
	local scale = math.tan(math.rad(currentFov / 2)) / math.tan(math.rad(initialFOV / 2))
	UserInputService.MouseDeltaSensitivity = (initialSens / SENSIVITY_DIVIDER) * scale
end

function funcs.toggleFirstPerson()
	firstPersonStep = 1
	firstPersonMode = not firstPersonMode

	local camera = workspace.CurrentCamera
	assert(camera)
	if firstPersonMode then
		CursorController.disableCursor()
		initialFOV = camera.FieldOfView
		initialSens = UserInputService.MouseDeltaSensitivity

		assert(initialFOV)
		camera.FieldOfView = initialFOV - funcs.getFirstPersonZoom()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		funcs.updateFirstPersonSensivity()

		cleaner:add(RunService.PreRender:Connect(function()
			if turretInfo and firstPersonMode then
				camera.CFrame = CFrame.new(turretInfo.CameraFirstPerson.CFrame.Position) * CFrame.fromOrientation(camera.CFrame:ToOrientation())
			end
		end))
	else
		cleaner:disconnectAll()
		funcs.exitFirstPerson()
	end
end

function funcs.exitFirstPerson()
	workspace.CurrentCamera.FieldOfView = initialFOV 
	UserInputService.MouseDeltaSensitivity = initialSens 
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	CursorController.enableCursor()
end

function funcs.zoomInFirstPerson()
	if not firstPersonMode then return end
	assert(turretInfo and initialFOV)

	local steps = turretInfo.TurretConfig.ZoomConfig.ZoomSteps
	if firstPersonStep < #steps then
		firstPersonStep += 1 
	end

	workspace.CurrentCamera.FieldOfView = initialFOV - funcs.getFirstPersonZoom()
	funcs.updateFirstPersonSensivity()
end

function funcs.zoomOutFirstPerson()
	if not firstPersonMode then return end
	assert(initialFOV)

	if firstPersonStep > 1 then
		firstPersonStep -= 1 
	end

	workspace.CurrentCamera.FieldOfView = initialFOV - funcs.getFirstPersonZoom()
	funcs.updateFirstPersonSensivity()
end

function funcs.getFirstPersonZoom(): number
	assert(turretInfo)
	local steps = turretInfo.TurretConfig.ZoomConfig.ZoomSteps
	if firstPersonStep < 1 or firstPersonStep > #steps then
		return 0
	else
		return steps[firstPersonStep]
	end
end

-- SUBSCRIPTIONS
UserInputService.InputBegan:Connect(funcs.handleInputBegan)
TurretViewController.TurretViewSet:connect(funcs.handleTurretViewSet)
TurretViewController.TurretViewCleared:connect(funcs.handleTurretViewCleared)

return module
