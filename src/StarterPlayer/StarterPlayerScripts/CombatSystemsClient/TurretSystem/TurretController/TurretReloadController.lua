--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local TurretSystemConfig = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.TurretSystemConfig)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- IMPORTS INTERNAL
local TurretSoundController = require(script.Parent.TurretSoundController)
local TurretStateController = require(script.Parent.TurretStateController)
local TurretViewController = require(script.Parent.TurretViewController)

-- ROBLOX OBJECTS
-- C->S
local reloadRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ClientToServer.ReloadTurret
local switchShellsRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ClientToServer.SwitchShells
local switchGunRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ClientToServer.SwitchGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ReplicateReload

-- FINALS
local cleaner = ConnectionCleaner.new()

-- STATE
local turretInfo: TurretUtil.TurretInfo?
local turretState: TurretUtil.TurretStateInfo?
local reloading = false
local reloadingCoax = false

-- PUBLIC EVENTS
module.ReloadStarted = Signal.new() -- (duration: number)
module.GunSwitched = Signal.new() -- (isMain: boolean)

-- INTERNAL FUNCTIONS
function funcs.handleTurretViewSet(newTurretInfo: TurretUtil.TurretInfo)
	turretInfo = newTurretInfo
end

function funcs.handleTurretViewCleared()
	cleaner:disconnectAll()
	turretInfo = nil
	turretState = nil
	reloading = false
	reloadingCoax = false
end

function funcs.handleTurretStateChanged(newTurretState: TurretUtil.TurretStateInfo)
	turretState = newTurretState
end

function funcs.handleInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not turretInfo or not turretState then return end

	local bindings = TurretSystemConfig.KeyBindings
	if turretInfo.TurretConfig.GunConfig.EnableCoax then
		if input.KeyCode == bindings.MainGunKey and not turretState.UsingMainGun then
			funcs.switchGun(true)
			module.GunSwitched:fire(true)
			return
		elseif input.KeyCode == bindings.CoaxGunKey and turretState.UsingMainGun then
			funcs.switchGun(false)
			module.GunSwitched:fire(false)
			return
		end
	end

	if reloading or reloadingCoax then return end

	local clipSize: number? = TurretStateController.getCurrentClipSize()
	assert(clipSize)

	if input.KeyCode == bindings.ReloadKey or (input.UserInputType == Enum.UserInputType.MouseButton1 and clipSize == 0) then
		funcs.reloadTurret(turretState.UsingMainGun)
	elseif input.KeyCode == bindings.SwitchShellsKey and turretState.UsingMainGun then
		funcs.switchShells()
	end
end

function funcs.reloadTurret(usingMain: boolean)
	assert(turretInfo and turretState)
	if usingMain and reloading then return end
	if not usingMain and reloadingCoax then return end

	local currentClipSize: number? = TurretStateController.getCurrentClipSize()
	local currentStoredAmmo: number? = TurretStateController.getCurrentStoredAmmo()
	assert(currentClipSize and currentStoredAmmo)
	if currentClipSize == funcs.getMaxClipSize() then return end
	if currentStoredAmmo == 0 then return end

	if usingMain then
		reloading = true
	else
		reloadingCoax = true
	end

	local reloadDuration: number = funcs.getReloadDuration()
	module.ReloadStarted:fire(reloadDuration)

	cleaner:add(task.delay(reloadDuration, function()
		if usingMain then
			reloading = false
		else
			reloadingCoax = false
		end
		reloadRemote:FireServer(usingMain)
	end))

	TurretSoundController.play(turretState.UsingMainGun and "Reload" or "ReloadCoax", turretInfo.PitchMotor.Part1 :: BasePart)
	replicateReloadRemote:FireServer(false, turretState.UsingMainGun)
end

function funcs.switchShells()
	assert(turretInfo and turretState)
	if reloading then return end
	if not turretState.UsingMainGun then return end
	if #turretInfo.TurretConfig.GunConfig.AmmoTypes == 1 then return end
	reloading = true

	local reloadDuration: number = funcs.getReloadDuration()
	module.ReloadStarted:fire(reloadDuration)

	cleaner:add(task.delay(reloadDuration, function()
		reloading = false
		switchShellsRemote:FireServer()
	end))

	TurretSoundController.play("Switch", turretInfo.PitchMotor.Part1 :: BasePart)
	replicateReloadRemote:FireServer(true, turretState.UsingMainGun)
end

function funcs.switchGun(usingMainGun: boolean)
	assert(turretInfo)
	switchGunRemote:FireServer(usingMainGun)
	local soundParent = turretInfo.YawMotor.Part0 :: BasePart
	TurretSoundController.play("CoaxSelect", soundParent)
end

function funcs.getMaxClipSize(): number
	assert(turretInfo and turretState)
	local gunConfig = turretInfo.TurretConfig.GunConfig
	return turretState.UsingMainGun and gunConfig.ClipSize or gunConfig.CoaxConfig.ClipSize
end

function funcs.getReloadDuration(): number
	assert(turretInfo and turretState)
	local gunConfig = turretInfo.TurretConfig.GunConfig
	return turretState.UsingMainGun and gunConfig.ReloadDuration or gunConfig.CoaxConfig.ReloadDuration
end

-- SUBSCRIPTIONS
UserInputService.InputBegan:Connect(funcs.handleInputBegan)
TurretViewController.TurretViewSet:connect(funcs.handleTurretViewSet)
TurretViewController.TurretViewCleared:connect(funcs.handleTurretViewCleared)
TurretViewController.TurretStateChanged:connect(funcs.handleTurretStateChanged)

return module
