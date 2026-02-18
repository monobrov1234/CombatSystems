--!strict

--[[
	GunController (Client-Side)
	
	This module handles client-side gun interactions for the CombatSystemsClient.
	It manages gun equipping/unequipping, firing, reloading, and related effects like animations, sounds, recoil, and UI updates.
	
	The script listens for gun tools added to the player's backpack or character, loads animations, tracks gun state (ammo, mag size),
	and handles user inputs for firing and reloading. It communicates with the server via remotes for state synchronization
	and replication of actions like firing and reloading to other clients.
]]

local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleanerModule)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local GunConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunConfig)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtilModule)
local RecoilUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.CameraRecoilUtilModule)
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)
local MovementController = require(PlayerScripts.CombatSystemsClient.MovementSystem.MovementControllerModule)
local CursorController = require(PlayerScripts.CombatSystemsClient.GunSystem.ClientFX.CursorController.CursorControllerModule)

-- IMPORTS INTERNAL
local BackpackController = require(script.BackpackControllerModule)
local GuiController = require(script.GuiControllerModule)
require(script.HandlingControllerModule)

-- ROBLOX OBJECTS
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- REMOTES
-- S->C
local replicateFireRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ServerToClient.ReplicateFireGun
-- C->S
local reloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ClientToServer.ReloadGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ReplicateReloadGun

-- FINALS
local log: Logger.SelfObject = Logger.new("GunController")
local cleaner = ConnectionCleaner.new()

-- STATE
local guiController: GuiController.SelfObject?
local recoilUtil: RecoilUtil.SelfObject?
local raycastParams: RaycastParams?

local autoFireConnection: RBXScriptConnection?
local isFiring = false
local reloading = false

-- animations
local idle = false
local sprintHold = false
local patrol = false

-- Handles gun equipping: Sets up necessary objects for gui and gun logic to work
function funcs.handleGunEquipped(gunInfo: GunUtil.GunInfo)
	local character: Model? = player.Character
	if not character then return end
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- raycastparams to ignore own character and other projectiles while shooting
	raycastParams = RaycastParams.new()
	assert(raycastParams)
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character, gunInfo.Tool, GunSystemConfig.ProjectileFolder }

	-- initialize gui
	guiController = GuiController.new(gunInfo)
	assert(guiController)

	-- retrieve server state to update gui text
	local state: BackpackController.GunState? = BackpackController.getStateFor(gunInfo.Tool)
	assert(state) -- should not happen

	-- update hud and enable gui
	guiController:updateHud(state.SharedState.MagSize, state.SharedState.AmmoSize)
	guiController:enableGui()

	-- initialize recoil util
	recoilUtil = RecoilUtil.new()
	assert(recoilUtil)
	recoilUtil:Start()

	CursorController.enableCursor()
	log:debug("Client gun equipped: {}", gunInfo.Tool.Name)

	-- if already running and sprinting - toggle sprint hold
	if MovementController.isSprinting() and humanoid.MoveDirection.Magnitude ~= 0 then
		funcs.setSprintHold(true, gunInfo)
	else -- if not, toggle default idle anim
		funcs.setIdle(true, gunInfo)
	end
end

-- Handles gun unequipping: Cleans up connections, GUI, recoil, etc.
function funcs.handleGunUnequipped(gunInfo: GunUtil.GunInfo)
	cleaner:disconnectAll()

	-- disable and destroy gui
	assert(guiController)
	guiController:disableGui()
	guiController:destroy()
	guiController = nil
	CursorController.disableCursor()

	-- destroy recoil util
	assert(recoilUtil)
	recoilUtil:Destroy()
	recoilUtil = nil

	-- stop reloading and firing
	funcs.stopAutoFire()
	reloading = false
	raycastParams = nil

	idle = false
	sprintHold = false
	patrol = false

	log:debug("Client gun unequipped: {}", gunInfo.Tool.Name)
end

-- Processes user input for firing (MouseButton1) or reloading (R key).
function funcs.handleInput(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 
			and input.KeyCode ~= GunConfig.KeyBindings.ReloadKey 
			and input.KeyCode ~= GunConfig.KeyBindings.PatrolKey then return end -- some unknown key pressed, exit

	local equippedGun: GunUtil.GunInfo? = BackpackController.getEquippedGun()
	if not equippedGun then return end -- no gun equipped, exit
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end -- humanoid died, exit
	if reloading then return end -- prohibit any action if the gun is reloading

	local state: BackpackController.GunState? = BackpackController.getStateFor(equippedGun.Tool)
	assert(state)

	-- patrol (G)
	if input.KeyCode == GunConfig.KeyBindings.PatrolKey then
		if MovementController.isSprinting() and humanoid.MoveDirection.Magnitude ~= 0 then return end -- no patrol when running while sprinting, but allow patrol when standing while sprinting
		if isFiring then return end -- no patrol when firing
		if reloading then return end -- no patrol when reloading
		if patrol then
			funcs.setPatrol(false, equippedGun)
		else
			funcs.setPatrol(true, equippedGun)
		end
		return
	end

	-- firing (LMB)
	local needReload = false -- auto reload on empty mag
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if state.SharedState.MagSize > 0 then
			funcs.startAutoFire(equippedGun)
		else
			needReload = true
		end
	end

	-- reloading (R)
	-- only allow reload if nothing is reloading
	if input.KeyCode == GunConfig.KeyBindings.ReloadKey or needReload then
		funcs.reloadGun(equippedGun) 
	end
end

-- Stops auto-fire when MouseButton1 is released.
function funcs.handleInputEnd(input: InputObject, gameProccessed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then funcs.stopAutoFire() end
end

-- Starts the auto-fire loop if not already firing.
function funcs.startAutoFire(gunInfo: GunUtil.GunInfo)
	if isFiring then return end
	isFiring = true
	autoFireConnection = cleaner:add(RunService.Heartbeat:Connect(function(deltaTime: number)
		-- reset sprint
		MovementController.setSprinting(false)
		funcs.fireGun(gunInfo)
	end)) :: RBXScriptConnection
end

-- Stops the auto-fire loop.
function funcs.stopAutoFire()
	if autoFireConnection then cleaner:disconnect(autoFireConnection) end
	isFiring = false
end

-- Fires a single shot: Checks firerate, fires munition, updates state, plays anim/recoil/sound.
-- Returns true if fired successfully.
function funcs.fireGun(gunInfo: GunUtil.GunInfo)
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

	local state: BackpackController.GunState? = BackpackController.getStateFor(gunInfo.Tool)
	assert(state)
	if state.SharedState.MagSize <= 0 then return end

	-- firerate check
	local clock = os.clock()
	if clock - state.LastShootTime < 60 / gunInfo.Config.GunConfig.FirerateRPM then return end

	-- fire
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
	state.LastShootTime = clock

	-- update ammo and mag size in gui
	assert(guiController)
	guiController:updateHud(state.SharedState.MagSize, state.SharedState.AmmoSize)

	-- reset patrol
	funcs.setPatrol(false, gunInfo)

	local shootAnim = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("Recoil"))
	assert(shootAnim, "No shoot animation for gun " .. gunInfo.Tool.Name)
	shootAnim:Play()

	-- recoil
	local recoilConfig = gunInfo.Config.GunConfig.RecoilConfig
	assert(recoilUtil)
	recoilUtil:Kick(recoilConfig.Pitch, recoilConfig.Yaw, nil, recoilConfig.Strength, recoilConfig.LerpTime)

	-- sound
	funcs.playSound("Fire", gunInfo.FiringPoint)
end

-- Initiates reload: Plays anim, delays, fires server remote, marks dirty.
function funcs.reloadGun(gunInfo: GunUtil.GunInfo)
	if reloading then return end

	local state: BackpackController.GunState? = BackpackController.getStateFor(gunInfo.Tool)
	assert(state)
	if state.SharedState.MagSize >= gunInfo.Config.GunConfig.MagSize then return end -- do not allow reload full mag
	if state.SharedState.AmmoSize <= 0 then return end -- do not allow reload if ammo is empty
	if state.Dirty then return end -- already pending reload
	reloading = true

	-- reset patrol
	funcs.setPatrol(false, gunInfo)

	local reloadAnim = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("Reload"))
	assert(reloadAnim, "No reload anim for gun " .. gunInfo.Tool.Name)
	reloadAnim:Play()

	cleaner:add(task.delay(gunInfo.Config.GunConfig.ReloadDuration, function()
		reloadRemote:FireServer(gunInfo.Tool)
		reloadAnim:Stop()
		reloading = false
		state.Dirty = true
		log:debug("Reload finished")
	end))

	assert(guiController)
	guiController:startReload()

	-- sound
	funcs.playSound("Reload", gunInfo.AnimPart)
	replicateReloadRemote:FireServer()
	log:debug("Reloading gun...")
end

-- Sets idle animation
function funcs.setIdle(value: boolean, gunInfo: GunUtil.GunInfo)
	if idle == value then return end
	local idleAnim: AnimationTrack? = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("Idle"))
	if not idleAnim then return end

	idle = value
	if value then idleAnim:Play()
	else idleAnim:Stop() end
end

-- Sets patrol state (G)
function funcs.setPatrol(value: boolean, gunInfo: GunUtil.GunInfo)
	if patrol == value then return end
	local patrolAnim: AnimationTrack? = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("Patrol"))
	if not patrolAnim then return end

	patrol = value
	if value then patrolAnim:Play()
	else patrolAnim:Stop() end
end

-- Sets sprint hold state
function funcs.setSprintHold(value: boolean, gunInfo: GunUtil.GunInfo)
	if sprintHold == value then return end
	local sprintHoldAnim: AnimationTrack? = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("SprintHold"))
	if not sprintHoldAnim then return end

	sprintHold = value
	if sprintHold then sprintHoldAnim:Play()
	else sprintHoldAnim:Stop() end
end

-- Ensures correct animation behavior on sprinting state change
function funcs.handleSprintStateChange(oldState: boolean, newState: boolean)
	local equippedGun: GunUtil.GunInfo? = BackpackController.getEquippedGun()
	if not equippedGun then return end

	-- reset patrol on any state change
	funcs.setPatrol(false, equippedGun)

	-- when sprinting ended, reset sprintHold and play idle animation
	if not newState then
		funcs.setSprintHold(false, equippedGun)
		funcs.setIdle(true, equippedGun)
	end
end

-- Ensures correct animation behavior when the player is moving/standing while having sprinting set to true
function funcs.handleHumanoidMove()
	local equippedGun = BackpackController.getEquippedGun()
	if not equippedGun then return end
	if not MovementController.isSprinting() then return end

	if reloading then
		funcs.setSprintHold(false, equippedGun)
		funcs.setIdle(true, equippedGun)
		return
	end

	if sprintHold and humanoid.MoveDirection.Magnitude == 0 then -- standing while sprinting
		funcs.setSprintHold(false, equippedGun)
		-- enable idle when standing
		funcs.setIdle(true, equippedGun)
	elseif not sprintHold and humanoid.MoveDirection.Magnitude ~= 0 then -- running while sprinting
		funcs.setSprintHold(true, equippedGun)
		funcs.setPatrol(false, equippedGun)
		-- disable idle when running
		funcs.setIdle(false, equippedGun)
	end
end

-- Plays a sound attached to the soundParent (e.g., firing point or anim part).
-- Sounds are configured in server-side services.
function funcs.playSound(soundName: string, soundParent: Instance)
	local sound = soundParent:FindFirstChild(soundName) :: Sound?
	if sound then
		assert(sound:IsA("Sound"))
		sound:Play()
	end
end

-- SERVER REPLICATION

-- Handles replicated fire from other players (plays sound).
function funcs.handleReplicateFire(part: BasePart)
	funcs.playSound("Fire", part)
end

-- Handles replicated reload from other players (plays sound).
function funcs.handleReplicateReload(part: BasePart)
	funcs.playSound("Reload", part)
end

-- Handles gun state updation event from the server (mag size, ammo count). Happens in BackpackController.
function funcs.handleSetGunState(gunTool: Tool, newState: BackpackController.SharedGunState)
	local equippedGun: GunUtil.GunInfo? = BackpackController.getEquippedGun()
	assert(equippedGun)
	if gunTool == equippedGun.Tool then
		assert(guiController)
		guiController:updateHud(newState.MagSize, newState.AmmoSize)
	end
end

-- HOOKS

-- Updates character references and re-hooks backpack on respawn.
function funcs.updateCharacter(newCharacter: Model)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
end
player.CharacterAdded:Connect(funcs.updateCharacter)

-- SUBSCRIPTIONS
UserInputService.InputBegan:Connect(funcs.handleInput)
UserInputService.InputEnded:Connect(funcs.handleInputEnd)
replicateReloadRemote.OnClientEvent:Connect(funcs.handleReplicateReload)
replicateFireRemote.OnClientEvent:Connect(funcs.handleReplicateFire)
RunService.Heartbeat:Connect(funcs.handleHumanoidMove)

-- custom
MovementController.SprintStateChanged:connect(funcs.handleSprintStateChange)
BackpackController.GunEquipped:connect(funcs.handleGunEquipped)
BackpackController.GunUnequipped:connect(funcs.handleGunUnequipped)
BackpackController.SetGunState:connect(funcs.handleSetGunState)