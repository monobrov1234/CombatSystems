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

local toolAnim: Motor6D?
local autoFireConnection: RBXScriptConnection?
local isFiring = false
local reloading = false

-- Handles gun equipping: Sets up Motor6D for animation, raycast params, GUI, recoil, cursor.
function funcs.handleGunEquipped(gunInfo: GunUtil.GunInfo)
	local character: Model? = player.Character
	if not character then return end
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local torso = (humanoid.RigType == Enum.HumanoidRigType.R6
		and character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")) :: BasePart?
	if torso then
		toolAnim = Instance.new("Motor6D")
		assert(toolAnim)
		toolAnim.Name = "toolAnim"
		toolAnim.Part0 = torso
		toolAnim.Part1 = gunInfo.AnimPart
		toolAnim.Parent = torso

		-- i do not want gun model to be visible in unanimated position for a moment, hide the gun
		toolAnim.C0 = CFrame.new(0, 500, 0)

		local idleAnim = funcs.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder.Idle)
		assert(idleAnim, "No idle animation for gun " .. gunInfo.Tool.Name)
		idleAnim:Play()

		RunService.Heartbeat:Once(function()
			-- show the gun when animation is done
			toolAnim.C0 = CFrame.new(0, 0, 0)
		end)
	else 
		log:warn("Character torso not found!")
	end

	raycastParams = RaycastParams.new()
	assert(raycastParams)
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character, gunInfo.Tool, GunSystemConfig.ProjectileFolder }

	-- retrieve server state to update gui text
	local state: BackpackController.GunState? = BackpackController.getStateFor(gunInfo.Tool)
	assert(state) -- should not happen

	guiController = GuiController.new(gunInfo)
	assert(guiController)
	guiController:updateHud(state.SharedState.MagSize, state.SharedState.AmmoSize)
	guiController:enableGui()

	recoilUtil = RecoilUtil.new()
	assert(recoilUtil)
	recoilUtil:Start()

	CursorController.enableCursor()
	log:debug("Client gun equipped: {}", gunInfo.Tool.Name)
end

-- Handles gun unequipping: Stops animations, cleans up connections, GUI, recoil, etc.
function funcs.handleGunUnequipped(gunInfo: GunUtil.GunInfo)
	cleaner:disconnectAll()

	-- stop ALL animations
	local loadedAnims = BackpackController.getLoadedAnimsFor(gunInfo.Tool)
	assert(loadedAnims) -- should not happen
	for anim: Animation, track: AnimationTrack in pairs(loadedAnims) do
		track:Stop()
	end

	-- remove grip motor6d
	if toolAnim then toolAnim:Destroy() end

	-- disable gui
	assert(guiController)
	guiController:disableGui()
	guiController:destroy()
	guiController = nil
	CursorController.disableCursor()

	-- stop firing and destroy recoil util object
	assert(recoilUtil)
	recoilUtil:Destroy()
	recoilUtil = nil

	funcs.stopAutoFire()
	reloading = false
	raycastParams = nil

	log:debug("Client gun unequipped: {}", gunInfo.Tool.Name)
end

-- Processes user input for firing (MouseButton1) or reloading (R key).
function funcs.handleInput(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end

	local equippedGun: Tool? = BackpackController.getEquippedGun()
	if not equippedGun then return end -- no gun equipped, exit
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.KeyCode ~= GunConfig.KeyBindings.ReloadKey then return end -- some unknown key pressed, exit
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end -- humanoid died, exit
	if reloading then return end -- prohibit any action if the gun is reloading

	local gunInfo = GunUtil.parseGunInfo(equippedGun)
	local state: BackpackController.GunState? = BackpackController.getStateFor(equippedGun)
	assert(state)

	-- firing (LMB)
	local needReload = false -- auto reload on empty mag
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if state.SharedState.MagSize > 0 then
			funcs.startAutoFire(gunInfo)
		else
			needReload = true
		end
	end

	-- reloading (R)
	-- only allow reload if nothing is reloading
	if input.KeyCode == GunConfig.KeyBindings.ReloadKey or needReload then funcs.reloadGun(gunInfo) end
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

	local spreadConfig = gunInfo.Config.GunConfig.SpreadConfig
	local direction: Vector3 = mouse.Hit.Position - gunInfo.FiringPoint.CFrame.Position
	MunitionController.fireMunition(gunInfo.Config.GunConfig.AmmoType, gunInfo.FiringPoint, direction, raycastParams, spreadConfig.Yaw, spreadConfig.Pitch)
	state.SharedState.MagSize = math.max(0, state.SharedState.MagSize - 1)
	state.LastShootTime = clock

	assert(guiController)
	guiController:updateHud(state.SharedState.MagSize, state.SharedState.AmmoSize)

	local shootAnim = funcs.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder.Recoil)
	assert(shootAnim, "No shoot animation for gun " .. gunInfo.Tool.Name)
	shootAnim:Play()

	-- recoil
	local recoilConfig = gunInfo.Config.GunConfig.RecoilConfig
	assert(recoilUtil)
	recoilUtil:Kick(recoilConfig.Pitch, recoilConfig.Yaw, nil, recoilConfig.Strength, recoilConfig.LerpTime)

	-- sound
	funcs.playSound("Fire", gunInfo.FiringPoint)
end

-- Handles replicated fire from other players (plays sound).
function funcs.handleReplicateFire(part: BasePart)
	funcs.playSound("Fire", part)
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

	local reloadAnim = funcs.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder.Reload)
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

-- Handles replicated reload from other players (plays sound).
function funcs.handleReplicateReload(part: BasePart)
	funcs.playSound("Reload", part)
end

-- Handles gun state updation event from the server (mag size, ammo count). Happens in BackpackController.
function funcs.handleSetGunState(gunTool: Tool, newState: BackpackController.SharedGunState)
	assert(guiController)
	if gunTool == BackpackController.getEquippedGun() then 
		guiController:updateHud(newState.MagSize, newState.AmmoSize) 
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

-- Resolves a preloaded animation track for the given gun tool and animation instance.
function funcs.resolveAnim(gunTool: Tool, anim: Animation): AnimationTrack?
	local anims = BackpackController.getLoadedAnimsFor(gunTool)
	if anims then
		return anims[anim]
	else return nil end
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

-- custom
BackpackController.GunEquipped:connect(funcs.handleGunEquipped)
BackpackController.GunUnequipped:connect(funcs.handleGunUnequipped)
BackpackController.SetGunState:connect(funcs.handleSetGunState)