--[[
    Turret View Controller (Client-Side)
    @Monobrov1234

	Turret view is the turret model that player currently controls, and have UI displayed for it.
	Player can have only one turret view.
	It can be used for mounted turrets, vehicles where one player can both drive and control a turret, stationary turrets, etc.
]]

-- TODO: add strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleanerModule)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local TurretConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.TurretConfig)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)
local RecoilUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.CameraRecoilUtilModule)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)

local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)
local CursorController = require(PlayerScripts.CombatSystemsClient.GunSystem.ClientFX.CursorController.CursorControllerModule)

-- IMPORTS INTERNAL
local RotationController = require(script.RotationControllerModule)
local GuiController = require(script.GuiControllerModule)

-- ROBLOX OBJECTS
local mouse = player:GetMouse()

-- S->C
local setTurretStateRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ServerToClient.SetState
local replicateFireRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ServerToClient.ReplicateFire
-- C->S
local setTurretViewRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.SetTurretView
local reloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.ReloadTurret
local switchShellsRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.SwitchShells
local switchGunRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.SwitchGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ReplicateReload

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretViewController")
local SENSIVITY_DIVIDER = 2 -- will divide initial mouse sensivity by this value to calculate sensivity in first person mode

local turretInfo: TurretUtil.TurretInfo
local raycastParams: RaycastParams
local debugRayPart: Part?
local initialFOV: number
local initialSens: number
local cleaner = ConnectionCleaner.new()
local rotationController: typeof(RotationController)
local guiController: typeof(GuiController)
local recoilUtil = RecoilUtil.new()
recoilUtil:Start()

-- STATE
local turretState: TurretUtil.TurretStateInfo
local turretStateDirty = false -- set to true on reload, blocks any further firing or reloading
local isFiring = false
local autoFireConnection: RBXScriptConnection
local lastShootTime = 0
local lastShootTimeCoax = 0
local calculatingDrop = false
local reloading = false
local reloadingCoax = false
local firstPersonMode = false
local firstPersonStep = 1

-- PUBLIC API
function module.setTurretView(turretModel: Model?, customRayFilters: { Instance }?)
	if not turretModel then
		funcs.clearTurretView()
		return
	end
	log:debug("Setting local turret view to {}", turretModel.Name)

	local character: Model? = player.Character
	assert(character)
	turretInfo = TurretUtil.parseTurretInfo(turretModel)

	raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterDescendantsInstances = { turretInfo.TurretModel, character, GunSystemConfig.ProjectileFolder }
	if customRayFilters then
		for _, instance: Instance in ipairs(customRayFilters) do
			table.insert(filterDescendantsInstances, instance)
		end
	end
	raycastParams.FilterDescendantsInstances = filterDescendantsInstances

	initialFOV = workspace.Camera.FieldOfView
	initialSens = UserInputService.MouseDeltaSensitivity

	local yawBase = turretInfo.YawMotor.Part0
	rotationController = RotationController.new(
		turretInfo,
		raycastParams,
		yawBase:FindFirstChild("TraverseStart"),
		yawBase:FindFirstChild("Traverse"),
		yawBase:FindFirstChild("TraverseEnd")
	)
	guiController = GuiController.new(turretInfo, raycastParams)
	guiController:enableGui()

	cleaner:add(RunService.PreRender:Connect(function(deltaTime: number)
		if firstPersonMode then
			local camera = workspace.CurrentCamera
			camera.CFrame = CFrame.new(turretInfo.CameraFirstPerson.CFrame.Position) * CFrame.fromOrientation(camera.CFrame:ToOrientation())
		end

		guiController:updateHud(deltaTime, funcs.getSelectedMunition(), funcs.getClipSize(), funcs.getStoredAmmo())
	end))

	cleaner:add(RunService.PreSimulation:Connect(function(deltaTime: number)
		rotationController:updateTurretRotation(deltaTime)
	end))

	cleaner:add(RunService.Heartbeat:Connect(function(deltaTime: number)
		local selected = funcs.getSelectedMunition()
		guiController:updateCursor(turretState.UsingMainGun and turretInfo.FiringPoint or turretInfo.FiringPointCoax, selected)
		if turretInfo.TurretConfig.DropIndicatorType == "Automatic" then
			if funcs.canUseDropIndicator() then
				guiController:updateDropIndicator(selected)
			else
				guiController:hideDropIndicator()
			end
		end
	end))

	cleaner:add(RunService.Heartbeat:Once(function()
		CursorController.enableCursor()
	end))

	-- notify server about new view, server will verify it and auto clear when turret view will be cleared
	setTurretViewRemote:FireServer(turretInfo.TurretModel)
	log:debug("Local turret view set")
end

function module.getCurrentTurretInfo(): TurretUtil.TurretInfo?
	return turretInfo
end

-- PRIVATE FUNCTIONS
function funcs.clearTurretView()
	cleaner:disconnectAll()

	if firstPersonMode then funcs.toggleFirstPerson() end

	rotationController:destroy()
	rotationController = nil
	guiController:disableGui()
	guiController:destroy()
	guiController = nil

	turretInfo = nil
	raycastParams = nil
	turretState = nil
	turretStateDirty = false

	isFiring = false
	lastShootTime = 0
	lastShootTimeCoax = 0
	calculatingDrop = false
	reloading = false
	reloadingCoax = false
	firstPersonMode = false
	firstPersonStep = 1

	CursorController.disableCursor()
end

-- server updates turret state when player enters the turret and on reload
function funcs.handleSetTurretState(newTurretState: TurretUtil.TurretStateInfo)
	turretState = newTurretState
	turretStateDirty = false
end

function funcs.handleInput(input: InputObject, gameProccessed: boolean)
	if gameProccessed then return end
	if not turretInfo then return end
	local bindings = TurretConfig.KeyBindings

	-- first person mode (Q)
	if input.KeyCode == bindings.FirstPersonMode.ToggleKey then
		funcs.toggleFirstPerson()
	elseif firstPersonMode then
		if input.KeyCode == bindings.FirstPersonMode.ZoomInKey then
			funcs.zoomInFirstPerson()
		elseif input.KeyCode == bindings.FirstPersonMode.ZoomOutKey then
			funcs.zoomOutFirstPerson()
		end
	end

	-- manual drop indicator (P)
	if input.KeyCode == bindings.CalculateDropKey and turretInfo.TurretConfig.DropIndicatorType == "Manual" then funcs.calculateDrop() end

	if not turretStateDirty then
		-- gun switching (keys 1, 2)
		if turretInfo.TurretConfig.GunConfig.EnableCoax then
			if input.KeyCode == bindings.MainGunKey and not turretState.UsingMainGun then
				funcs.switchGun(true)
				funcs.stopAutoFire()
				return
			elseif input.KeyCode == bindings.CoaxGunKey and turretState.UsingMainGun then
				funcs.switchGun(false)
				funcs.stopAutoFire()
				return
			end
		end

		-- firing (LMB)
		-- only allow fire if the selected gun isn't reloading
		local needReload = false
		if not funcs.isReloading() then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if funcs.getClipSize() > 0 then
					funcs.startAutoFire()
				else
					needReload = true
				end
			end
		end

		-- reloading & switching shells (R, V)
		-- only allow reload if nothing is reloading
		if not reloading and not reloadingCoax then
			if input.KeyCode == bindings.ReloadKey or needReload then
				funcs.reloadTurret()
			elseif input.KeyCode == bindings.SwitchShellsKey then
				funcs.switchShells()
			end
		end
	end
end

function funcs.handleInputEnd(input: InputObject, gameProccessed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then funcs.stopAutoFire() end
end

function funcs.switchGun(usingMainGun: boolean)
	turretStateDirty = true
	switchGunRemote:FireServer(usingMainGun)

	-- sound
	funcs.playSound("CoaxSelect", turretInfo.YawMotor.Part0)
end

function funcs.startAutoFire()
	if isFiring then return end
	isFiring = true
	autoFireConnection = cleaner:add(RunService.Heartbeat:Connect(function()
		if not turretStateDirty then funcs.fireTurret() end
	end))
end

function funcs.stopAutoFire()
	if autoFireConnection then cleaner:disconnect(autoFireConnection) end
	isFiring = false
end

function funcs.fireTurret()
	if funcs.getClipSize() <= 0 then return end
	-- firerate check
	if os.clock() - funcs.getLastShootTime() < 60 / funcs.getFirerateRPM() then return end

	local firingPart = turretState.UsingMainGun and turretInfo.FiringPoint or turretInfo.FiringPointCoax
	local spreadConfig = turretState.UsingMainGun and turretInfo.TurretConfig.GunConfig.SpreadConfig
		or turretInfo.TurretConfig.GunConfig.CoaxConfig.SpreadConfig

	local pitchTarget = turretInfo.PitchMotor.Part1
	local direction = pitchTarget.CFrame.LookVector
	MunitionController.fireMunition(funcs.getSelectedMunition(), firingPart, direction, raycastParams, spreadConfig.Yaw, spreadConfig.Pitch)
	funcs.setClipSize(funcs.getClipSize() - 1)
	funcs.setLastShootTime(os.clock())

	-- recoil
	local recoilConfig = turretState.UsingMainGun and turretInfo.TurretConfig.GunConfig.RecoilConfig
		or turretInfo.TurretConfig.GunConfig.CoaxConfig.RecoilConfig
	recoilUtil:Kick(recoilConfig.Pitch, recoilConfig.Yaw, nil, recoilConfig.Strength, recoilConfig.LerpTime)

	-- sound
	funcs.playSound(turretState.UsingMainGun and "Fire" or "FireCoax", firingPart)
end

function funcs.handleReplicateFire(part: BasePart, usingMainGun: boolean)
	funcs.playSound(usingMainGun and "Fire" or "FireCoax", part)
end

function funcs.calculateDrop()
	if not funcs.canUseDropIndicator() then return end
	if calculatingDrop then return end
	calculatingDrop = true

	guiController:calculateDrop(function()
		guiController:updateDropIndicator(funcs.getSelectedMunition())
		cleaner:add(task.delay(turretInfo.TurretConfig.DropManualStayDuration, function()
			guiController:hideDropIndicator()
			calculatingDrop = false
		end))
	end)
end

function funcs.canUseDropIndicator(): boolean
	local config = MunitionConfigUtil.getConfig(funcs.getSelectedMunition())
	return turretInfo.TurretConfig.DropIndicatorType ~= "None" and config.EnableBallistics
end

-- separate reloading progress for main and coax guns
function funcs.reloadTurret()
	local usingMain = turretState.UsingMainGun
	assert(turretState.UsingMainGun and not reloading or not reloadingCoax) -- this should never fail because of early check
	if funcs.getClipSize() == funcs.getMaxClipSize() then return end -- check if clip is full
	if funcs.getStoredAmmo() == 0 then return end -- check if ammo is available
	funcs.setReloading(true)

	local reloadDuration = funcs.getReloadDuration()
	guiController:startReload(reloadDuration)
	cleaner:add(task.delay(reloadDuration, function()
		turretStateDirty = true
		if usingMain then
			reloading = false
			lastShootTime = 0
		else
			reloadingCoax = false
			lastShootTimeCoax = 0
		end
		reloadRemote:FireServer(usingMain)
	end))

	-- sound
	replicateReloadRemote:FireServer(false, turretState.UsingMainGun)
	funcs.playSound(turretState.UsingMainGun and "Reload" or "ReloadCoax", turretInfo.PitchMotor.Part1)
end

function funcs.switchShells()
	if not turretState.UsingMainGun then return end -- will not work if coax is selected
	if #turretInfo.TurretConfig.GunConfig.AmmoTypes == 1 then return end -- nothing to switch
	assert(not reloading)
	reloading = true

	local reloadDuration = funcs.getReloadDuration()
	guiController:startReload(reloadDuration)
	cleaner:add(task.delay(reloadDuration, function()
		turretStateDirty = true
		reloading = false
		lastShootTime = 0
		switchShellsRemote:FireServer()
	end))

	-- sound
	replicateReloadRemote:FireServer(true, turretState.UsingMainGun)
	funcs.playSound("Switch", turretInfo.PitchMotor.Part1)
end

function funcs.handleReplicateReload(part: BasePart, switch: boolean, usingMainGun: boolean)
	if switch then
		funcs.playSound("Switch", part)
	else
		funcs.playSound(usingMainGun and "Reload" or "ReloadCoax", part)
	end
end

function funcs.toggleFirstPerson()
	firstPersonStep = 1
	firstPersonMode = not firstPersonMode

	local camera = workspace.CurrentCamera
	if firstPersonMode then
		CursorController.disableCursor()
		camera.FieldOfView = initialFOV - funcs.getFirstPersonZoom()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		funcs.updateFirstPersonSensivity()
	else
		camera.FieldOfView = initialFOV
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseDeltaSensitivity = initialSens
		CursorController.enableCursor()
	end
end

function funcs.zoomInFirstPerson()
	local steps = turretInfo.TurretConfig.ZoomConfig.ZoomSteps
	if firstPersonStep < #steps then
		firstPersonStep += 1
	end
	workspace.CurrentCamera.FieldOfView = initialFOV - funcs.getFirstPersonZoom()
	funcs.updateFirstPersonSensivity()
end

function funcs.zoomOutFirstPerson()
	local steps = turretInfo.TurretConfig.ZoomConfig.ZoomSteps
	if firstPersonStep > 1 then
		firstPersonStep -= 1
	end
	workspace.CurrentCamera.FieldOfView = initialFOV - funcs.getFirstPersonZoom()
	funcs.updateFirstPersonSensivity()
end

function funcs.updateFirstPersonSensivity()
	local currentFov = workspace.CurrentCamera.FieldOfView
	local scale = math.tan(math.rad(currentFov / 2)) / math.tan(math.rad(initialFOV / 2))
	local sensivity = initialSens / SENSIVITY_DIVIDER
	UserInputService.MouseDeltaSensitivity = sensivity * scale
end

function funcs.getFirstPersonZoom()
	return turretInfo.TurretConfig.ZoomConfig.ZoomSteps[firstPersonStep]
end

-- will play sound that MAY be child of a soundParent instance
-- sounds are added to parts in server TurretRigService
function funcs.playSound(soundName: string, soundParent: Instance)
	local sound = soundParent:FindFirstChild(soundName) :: Sound?
	if sound then
		assert(sound:IsA("Sound"))
		sound:Play()
	end
end

-- will set/return values for current selected gun (main/coax)

function funcs.getSelectedMunition(): string
	return turretState.UsingMainGun and turretState.SelectedMunition or turretInfo.TurretConfig.GunConfig.CoaxConfig.AmmoType
end

function funcs.getFirerateRPM(): number
	return turretState.UsingMainGun and turretInfo.TurretConfig.GunConfig.FirerateRPM or turretInfo.TurretConfig.GunConfig.CoaxConfig.FirerateRPM
end

function funcs.isReloading(): boolean
	if turretState.UsingMainGun then
		return reloading
	else
		return reloadingCoax
	end
end

function funcs.setReloading(newReloading: boolean)
	if turretState.UsingMainGun then
		reloading = newReloading
	else
		reloadingCoax = newReloading
	end
end

function funcs.getReloadDuration()
	return turretState.UsingMainGun and turretInfo.TurretConfig.GunConfig.ReloadDuration or turretInfo.TurretConfig.GunConfig.CoaxConfig.ReloadDuration
end

function funcs.getMaxClipSize(): number
	return turretState.UsingMainGun and turretInfo.TurretConfig.GunConfig.ClipSize or turretInfo.TurretConfig.GunConfig.CoaxConfig.ClipSize
end

function funcs.getClipSize(): number
	return turretState.UsingMainGun and turretState.ClipSizeStorage[turretState.SelectedMunition] or turretState.CoaxClipSize
end

function funcs.setClipSize(clipSize: number)
	if turretState.UsingMainGun then
		turretState.ClipSizeStorage[turretState.SelectedMunition] = clipSize
	else
		turretState.CoaxClipSize = clipSize
	end
end

function funcs.getStoredAmmo(): number
	return turretState.UsingMainGun and turretState.MunitionStorage[turretState.SelectedMunition] or turretState.CoaxAmmoSize
end

function funcs.setStoredAmmo(newStored: number)
	if turretState.UsingMainGun then
		turretState.MunitionStorage[turretState.SelectedMunition] = newStored
	else
		turretState.CoaxAmmoSize = newStored
	end
end

function funcs.getLastShootTime(): number
	return turretState.UsingMainGun and lastShootTime or lastShootTimeCoax
end

function funcs.setLastShootTime(newTime: number)
	if turretState.UsingMainGun then
		lastShootTime = newTime
	else
		lastShootTimeCoax = newTime
	end
end

UserInputService.InputBegan:Connect(funcs.handleInput)
UserInputService.InputEnded:Connect(funcs.handleInputEnd)

replicateFireRemote.OnClientEvent:Connect(funcs.handleReplicateFire)
replicateReloadRemote.OnClientEvent:Connect(funcs.handleReplicateReload)
setTurretStateRemote.OnClientEvent:Connect(funcs.handleSetTurretState)

player.CharacterAdded:Connect(function(newCharacter: Model)
	if turretInfo then funcs.clearTurretView() end
end)

log:info("Module loaded")

return module
