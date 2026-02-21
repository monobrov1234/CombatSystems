--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local CameraRecoilUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.CameraRecoilUtil)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)
local SoundUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.SoundUtil)
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionController)

-- IMPORTS INTERNAL
local GunController = require(script.Parent.GunController)
local BackpackController = require(script.Parent.BackpackController)
local GunReloadController = require(script.Parent.GunReloadController)
local MovementController = require(PlayerScripts.CombatSystemsClient.MovementSystem.MovementController)

-- ROBLOX OBJECTS
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- REMOTES
-- S->C
local replicateFireRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.Core.ServerToClient.ReplicateFireGun

-- FINALS
local cleaner = ConnectionCleaner.new()

-- STATE
local gunInfo: GunUtil.GunInfo?
local recoilUtil: CameraRecoilUtil.SelfObject?
local isFiring = false
local autoFireConnection: RBXScriptConnection?

-- PUBLIC EVENTS
module.FireGun = Signal.new()

-- PUBLIC API
function module.isFiring(): boolean
	return isFiring
end

-- INTERNAL FUNCTIONS
function funcs.handleGunEquipped(newGunInfo: GunUtil.GunInfo)
	gunInfo = newGunInfo
	recoilUtil = CameraRecoilUtil.new()
	assert(recoilUtil)
	recoilUtil:Start()
end

function funcs.handleGunUnequipped()
	cleaner:disconnectAll()
	funcs.stopAutoFire()
	if recoilUtil then
		recoilUtil:Destroy()
		recoilUtil = nil
	end
	gunInfo = nil
end

function funcs.handleInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then 
		if not funcs.canShoot() then return end
		funcs.startAutoFire()
	end
end

function funcs.handleInputEnded(input: InputObject, gameProcessed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		funcs.stopAutoFire()
	end
end

function funcs.handleReplicateFire(part: BasePart)
	SoundUtil.play("Fire", part)
end

function funcs.startAutoFire()
	assert(gunInfo)
	if isFiring then return end
	isFiring = true
	autoFireConnection = cleaner:add(RunService.Heartbeat:Connect(function(deltaTime: number)
		MovementController.setSprinting(false)
		funcs.tryFireGun()
	end)) :: RBXScriptConnection
end

function funcs.stopAutoFire()
	if autoFireConnection then
		cleaner:disconnect(autoFireConnection)
		autoFireConnection = nil
	end
	isFiring = false
end

function funcs.tryFireGun()
	if not gunInfo then return end
	local state: BackpackController.GunState? = BackpackController.getStateFor(gunInfo.Tool)
	assert(state)

	if not funcs.canShoot() then
		if state.SharedState.MagSize <= 0 then
			GunReloadController.tryReloadGun()
		end
		return
	end

	local raycastParams: RaycastParams? = GunController.getRaycastParams()
	assert(raycastParams)

	local spreadConfig = gunInfo.Config.GunConfig.SpreadConfig
	local direction: Vector3 = mouse.Hit.Position - gunInfo.FiringPoint.CFrame.Position
	MunitionController.fireMunition({
		MunitionName = gunInfo.Config.GunConfig.AmmoType,
		Origin = gunInfo.FiringPoint,
		DirectionVec = direction,
		RaycastParams = raycastParams,
		SpreadYawDeg = spreadConfig.Yaw,
		SpreadPitchDeg = spreadConfig.Pitch
	})

	state.SharedState.MagSize = math.max(0, state.SharedState.MagSize - 1)
	state.LastShootTime = os.clock()
	module.FireGun:fire()

	local shootAnim = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("Recoil"))
	assert(shootAnim, "No shoot animation for gun " .. gunInfo.Tool.Name)
	shootAnim:Play()

	local recoilConfig = gunInfo.Config.GunConfig.RecoilConfig
	assert(recoilUtil)
	recoilUtil:Kick(recoilConfig.Pitch, recoilConfig.Yaw, nil, recoilConfig.Strength, recoilConfig.LerpTime)

	SoundUtil.play("Fire", gunInfo.FiringPoint)
end

function funcs.canShoot(): boolean
	if not gunInfo then return false end
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
	if GunReloadController.isReloading() then return false end

	local state: BackpackController.GunState? = BackpackController.getStateFor(gunInfo.Tool)
	assert(state)
	if state.SharedState.MagSize <= 0 then return false end

	local clock = os.clock()
	if clock - state.LastShootTime < 60 / gunInfo.Config.GunConfig.FirerateRPM then return false end

	return true
end

player.CharacterAdded:Connect(function(newCharacter: Model)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
end)

-- SUBSCRIPTIONS
UserInputService.InputBegan:Connect(funcs.handleInputBegan)
UserInputService.InputEnded:Connect(funcs.handleInputEnded)
replicateFireRemote.OnClientEvent:Connect(funcs.handleReplicateFire)
-- custom
BackpackController.GunEquipped:connect(funcs.handleGunEquipped)
BackpackController.GunUnequipped:connect(funcs.handleGunUnequipped)

return module
