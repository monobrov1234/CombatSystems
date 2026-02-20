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

local TurretReloadController = require(script.Parent.TurretReloadController)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local RecoilUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.CameraRecoilUtil)
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionController)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local TurretViewController = require(script.Parent.TurretViewController)
local TurretSoundController = require(script.Parent.TurretSoundController)
local TurretStateController = require(script.Parent.TurretStateController)

-- FINALS
local cleaner = ConnectionCleaner.new()
local recoilUtil = RecoilUtil.new()
recoilUtil:Start()

-- STATE
local turretInfo: TurretUtil.TurretInfo?
local turretState: TurretUtil.TurretStateInfo?

local isFiring = false
local autoFireConnection: RBXScriptConnection?
local lastShootTime = 0
local lastShootTimeCoax = 0

-- INTERNAL FUNCTIONS
function funcs.handleTurretViewSet(newTurretInfo: TurretUtil.TurretInfo, customRayFilters: { Instance }?)
	turretInfo = newTurretInfo
end

function funcs.handleTurretViewCleared()
	cleaner:disconnectAll()

	funcs.stopAutoFire()
	lastShootTime = 0
	lastShootTimeCoax = 0

	turretInfo = nil
	turretState = nil
end

function funcs.handleTurretStateChanged(newTurretState: TurretUtil.TurretStateInfo)
	turretState = newTurretState
end

function funcs.handleInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not turretInfo then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		funcs.startAutoFire()
	end
end

function funcs.handleInputEnded(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not turretInfo then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		funcs.stopAutoFire()
	end
end

function funcs.handleGunSwitch()
	funcs.stopAutoFire()
end

function funcs.startAutoFire()
	if isFiring then return end
	if TurretStateController.getCurrentClipSize() <= 0 then return end
	isFiring = true
	autoFireConnection = cleaner:add(RunService.Heartbeat:Connect(funcs.fireTurret)) :: RBXScriptConnection
end

function funcs.stopAutoFire()
	if autoFireConnection then
		cleaner:disconnect(autoFireConnection)
		autoFireConnection = nil
	end
	isFiring = false
end

function funcs.fireTurret()
	local info = turretInfo
	local state = turretState
	local raycastParams: RaycastParams? = TurretStateController.getCurrentRaycastParams()

	if not info or not state or not raycastParams then return end
	if TurretStateController.getCurrentClipSize() <= 0 then return end

	local firerateRPM = TurretStateController.getFirerateRPM()
	if firerateRPM <= 0 then return end
	if os.clock() - funcs.getLastShootTime() < 60 / firerateRPM then return end

	local firingPart: BasePart = (state.UsingMainGun and info.FiringPoint or info.FiringPointCoax) :: BasePart
	local spreadConfig = state.UsingMainGun and info.TurretConfig.GunConfig.SpreadConfig
		or info.TurretConfig.GunConfig.CoaxConfig.SpreadConfig
	local direction = (info.PitchMotor.Part1 :: BasePart).CFrame.LookVector

	local selectedMunition: string? = TurretStateController.getCurrentSelectedMunition()
	assert(selectedMunition)
	MunitionController.fireMunition({
		MunitionName = selectedMunition,
		Origin = firingPart,
		DirectionVec = direction,
		RaycastParams = raycastParams,
		SpreadYawDeg = spreadConfig.Yaw,
		SpreadPitchDeg = spreadConfig.Pitch
	})

	local currentClipSize: number? = TurretStateController.getCurrentClipSize()
	assert(currentClipSize)
	TurretStateController.setClipSize(currentClipSize - 1)
	funcs.setLastShootTime(os.clock())

	local recoilConfig = state.UsingMainGun and info.TurretConfig.GunConfig.RecoilConfig
		or info.TurretConfig.GunConfig.CoaxConfig.RecoilConfig
	recoilUtil:Kick(recoilConfig.Pitch, recoilConfig.Yaw, nil, recoilConfig.Strength, recoilConfig.LerpTime)

	TurretSoundController.play(state.UsingMainGun and "Fire" or "FireCoax", firingPart)
end

function funcs.reset()
	cleaner:disconnectAll()
	isFiring = false
	lastShootTime = 0
	lastShootTimeCoax = 0
	if autoFireConnection then
		cleaner:disconnect(autoFireConnection)
		autoFireConnection = nil
	end
end

function funcs.getLastShootTime(): number
	assert(turretState)
	return turretState.UsingMainGun and lastShootTime or lastShootTimeCoax
end

function funcs.setLastShootTime(newTime: number)
	assert(turretState)
	if turretState.UsingMainGun then
		lastShootTime = newTime
	else
		lastShootTimeCoax = newTime
	end
end

-- SUBSCRIPTIONS
UserInputService.InputBegan:Connect(funcs.handleInputBegan)
UserInputService.InputEnded:Connect(funcs.handleInputEnded)
TurretViewController.TurretViewSet:connect(funcs.handleTurretViewSet)
TurretViewController.TurretStateChanged:connect(funcs.handleTurretStateChanged)
TurretViewController.TurretViewCleared:connect(funcs.handleTurretViewCleared)
TurretReloadController.GunSwitched:connect(funcs.handleGunSwitch)

return module
