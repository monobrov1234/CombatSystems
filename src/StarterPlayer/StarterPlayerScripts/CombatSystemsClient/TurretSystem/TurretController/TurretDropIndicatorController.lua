--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local TurretSystemConfig = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.TurretSystemConfig)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- IMPORTS INTERNAL
local TurretViewController = require(script.Parent.TurretViewController)
local TurretStateController = require(script.Parent.TurretStateController)

-- FINALS
local cleaner = ConnectionCleaner.new()

-- STATE
local turretInfo: TurretUtil.TurretInfo?
local calculatingDrop = false

-- PUBLIC EVENTS
module.DropCalculationRequested = Signal.new() -- (calcDuration, stayDuration, munitionName)
module.DropIndicatorRequested = Signal.new() -- (munitionName)
module.DropIndicatorHideRequested = Signal.new() -- ()

-- PUBLIC API
function module.canUseDropIndicator(): boolean
	return funcs.canUseDropIndicator()
end

-- INTERNAL FUNCTIONS
function funcs.handleTurretViewSet(newTurretInfo: TurretUtil.TurretInfo, customRayFilters: { Instance }?)
	turretInfo = newTurretInfo
end

function funcs.handleTurretViewCleared()
	cleaner:disconnectAll()
	calculatingDrop = false
	turretInfo = nil
	module.DropIndicatorHideRequested:fire()
end

function funcs.handleInputBegan(input: InputObject, gameProcessed: boolean)
	if not turretInfo then return end
	if input.KeyCode == TurretSystemConfig.KeyBindings.CalculateDropKey and turretInfo.TurretConfig.DropIndicatorType == "Manual" then
		funcs.calculateDrop()
	end
end

function funcs.handleHeartbeat()
	if not turretInfo then return end
	if turretInfo.TurretConfig.DropIndicatorType ~= "Automatic" then return end

	if funcs.canUseDropIndicator() then
		module.DropIndicatorRequested:fire(TurretStateController.getCurrentSelectedMunition())
	else
		module.DropIndicatorHideRequested:fire()
	end
end

function funcs.calculateDrop()
	if not turretInfo then return end
	if not funcs.canUseDropIndicator() then return end
	if calculatingDrop then return end
	calculatingDrop = true

	local munitionName = TurretStateController.getCurrentSelectedMunition()
	module.DropCalculationRequested:fire(
		turretInfo.TurretConfig.DropManualCalcDuration,
		turretInfo.TurretConfig.DropManualStayDuration,
		munitionName
	)
	cleaner:add(task.delay(turretInfo.TurretConfig.DropManualCalcDuration + turretInfo.TurretConfig.DropManualStayDuration, function()
		calculatingDrop = false
	end))
end

function funcs.canUseDropIndicator(): boolean
	assert(turretInfo)
	local selectedMunition: string? = TurretStateController.getCurrentSelectedMunition()
	assert(selectedMunition)
	local config = MunitionConfigUtil.getConfig(selectedMunition)
	return config and turretInfo.TurretConfig.DropIndicatorType ~= "None" and config.EnableBallistics
end

-- SUBSCRIPTIONS
UserInputService.InputBegan:Connect(funcs.handleInputBegan)
RunService.Heartbeat:Connect(funcs.handleHeartbeat)
TurretViewController.TurretViewSet:connect(funcs.handleTurretViewSet)
TurretViewController.TurretViewCleared:connect(funcs.handleTurretViewCleared)

return module
