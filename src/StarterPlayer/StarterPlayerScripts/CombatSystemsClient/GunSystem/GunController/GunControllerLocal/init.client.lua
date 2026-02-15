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
local GuiController = require(script.GuiControllerModule)

-- ROBLOX OBJECTS
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local animator: Animator = humanoid:WaitForChild("Animator")

-- S->C
local setStateRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ServerToClient.SetGunState
local replicateFireRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ServerToClient.ReplicateFireGun
-- C->S
local reloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ClientToServer.ReloadGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ReplicateReloadGun

-- FINALS
local log: Logger.SelfObject = Logger.new("GunController")
local cleaner = ConnectionCleaner.new()

local equippedGun: Tool
local raycastParams: RaycastParams
local guiController: typeof(GuiController)
local recoilUtil: typeof(RecoilUtil)

type SharedGunState = { -- changed by server sometimes
	MagSize: number,
	AmmoSize: number,
}
type GunState = {
	SharedState: SharedGunState,
	LastShootTime: number,
	Dirty: boolean, -- used to block reloads until server updates shared state
}
local stateTable: { [Tool]: GunState } = {} -- each gun have its GunState to remember mag size and other stuff
local loadedAnims: { [Tool]: { [Animation]: AnimationTrack } } = {} -- when new gun tool is added to backpack, its animations are loaded as tracks and put here

-- STATE
local toolAnim: Motor6D
local autoFireConnection: RBXScriptConnection
local isFiring = false
local reloading = false

function funcs.handleGunAdded(gunTool: Tool)
	if not gunTool:IsA("Tool") then return end
	if not GunUtil.validateGun(gunTool) then return end
	local state = stateTable[gunTool]
	if state then return end -- gun already registered

	local gunInfo = GunUtil.parseGunInfo(gunTool)
	gunTool.AncestryChanged:Connect(function(child: Instance, newParent: Instance)
		if child ~= gunTool then return end
		if newParent == player.Character then
			-- gun was equipped
			funcs.handleGunEquipped(gunInfo)
			equippedGun = gunInfo.Tool
		else
			if equippedGun == gunTool then
				-- gun was unequipped
				funcs.handleGunUnequipped(gunInfo)
				equippedGun = nil
			end

			if newParent ~= player.Backpack then
				-- gun was removed from inventory
				funcs.handleGunRemoved(gunInfo)
			end
		end
	end)

	-- load all gun animations when it was first added to the inventory
	loadedAnims[gunTool] = {}
	for _, anim: Animation in ipairs(gunInfo.Config.DecorConfig.AnimationsFolder:GetChildren()) do
		local track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action
		loadedAnims[gunTool][anim] = track
	end

	stateTable[gunTool] = {
		SharedState = {
			MagSize = gunInfo.Config.GunConfig.MagSize,
			AmmoSize = gunInfo.Config.GunConfig.AmmoSize,
		},
		LastShootTime = 0,
		Dirty = false,
	}

	log:debug("Client gun added to inventory: {}", gunTool.Name)
end

function funcs.handleGunRemoved(gunInfo: GunUtil.GunInfo)
	-- clean up all animation tracks on inventory remove
	for anim: Animation, track: AnimationTrack in pairs(loadedAnims[gunInfo.Tool]) do
		track:Destroy()
	end
	loadedAnims[gunInfo.Tool] = nil
	stateTable[gunInfo.Tool] = nil
	log:debug("Client gun removed from inventory: {}", gunInfo.Tool.Name)
end

function funcs.handleGunEquipped(gunInfo: GunUtil.GunInfo)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local torso = humanoid.RigType == Enum.HumanoidRigType.R6 and character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if torso then
		toolAnim = Instance.new("Motor6D")
		toolAnim.Name = "toolAnim"
		toolAnim.Part0 = torso
		toolAnim.Part1 = gunInfo.AnimPart
		toolAnim.Parent = torso

		local idleAnim = funcs.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder.Idle)
		idleAnim:Play()
	end

	raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character, gunInfo.Tool, GunSystemConfig.ProjectileFolder }

	guiController = GuiController.new(gunInfo)
	local state = stateTable[gunInfo.Tool]
	guiController:updateHud(state.SharedState.MagSize, state.SharedState.AmmoSize)
	guiController:enableGui()

	recoilUtil = RecoilUtil.new()
	recoilUtil:Start()

	CursorController.enableCursor()
	log:debug("Client gun equipped: {}", gunInfo.Tool.Name)
end

function funcs.handleGunUnequipped(gunInfo: GunUtil.GunInfo)
	cleaner:disconnectAll()

	-- stop ALL animations
	for anim: Animation, track: AnimationTrack in pairs(loadedAnims[gunInfo.Tool]) do
		track:Stop()
	end

	if toolAnim then toolAnim:Destroy() end

	guiController:disableGui()
	guiController:destroy()
	guiController = nil

	recoilUtil:Destroy()

	funcs.stopAutoFire()
	reloading = false

	stateTable[gunInfo.Tool].Dirty = false -- to prevent desync where dirty will be true forever
	raycastParams = nil

	CursorController.disableCursor()
	log:debug("Client gun unequipped: {}", gunInfo.Tool.Name)
end

function funcs.handleSetGunState(gunTool: Tool, newState: SharedGunState)
	local state = stateTable[gunTool]
	if state then
		state.SharedState = newState
		state.Dirty = false
		if gunTool == equippedGun then guiController:updateHud(newState.MagSize, newState.AmmoSize) end
	end
end

function funcs.handleInput(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not equippedGun then return end -- no gun equipped, exit
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.KeyCode ~= GunConfig.KeyBindings.ReloadKey then return end -- some unknown key pressed, exit
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end -- humanoid died, exit
	if reloading then return end -- prohibit any action if the gun is reloading

	local gunInfo = GunUtil.parseGunInfo(equippedGun)
	local state = stateTable[gunInfo.Tool]

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

function funcs.handleInputEnd(input: InputObject, gameProccessed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then funcs.stopAutoFire() end
end

function funcs.startAutoFire(gunInfo: GunUtil.GunInfo)
	if isFiring then return end
	isFiring = true
	autoFireConnection = cleaner:add(RunService.Heartbeat:Connect(function(deltaTime)
		-- reset sprint
		MovementController.setSprinting(false)
		funcs.fireGun(gunInfo)
	end))
end

function funcs.stopAutoFire()
	if autoFireConnection then cleaner:disconnect(autoFireConnection) end
	isFiring = false
end

function funcs.fireGun(gunInfo: GunUtil.GunInfo): boolean
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
	local state = stateTable[gunInfo.Tool]
	if state.SharedState.MagSize <= 0 then return end

	-- firerate check
	local clock = os.clock()
	if clock - state.LastShootTime < 60 / gunInfo.Config.GunConfig.FirerateRPM then return end

	local spreadConfig = gunInfo.Config.GunConfig.SpreadConfig
	local direction: Vector3 = mouse.Hit.Position - gunInfo.FiringPoint.CFrame.Position
	MunitionController.fireMunition(gunInfo.Config.GunConfig.AmmoType, gunInfo.FiringPoint, direction, raycastParams, spreadConfig.Yaw, spreadConfig.Pitch)
	state.SharedState.MagSize = math.max(0, state.SharedState.MagSize - 1)
	state.LastShootTime = clock

	guiController:updateHud(state.SharedState.MagSize, state.SharedState.AmmoSize)

	local shootAnim = funcs.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder.Recoil)
	shootAnim:Play()

	-- recoil
	local recoilConfig = gunInfo.Config.GunConfig.RecoilConfig
	recoilUtil:Kick(recoilConfig.Pitch, recoilConfig.Yaw, nil, recoilConfig.Strength, recoilConfig.LerpTime)

	-- sound
	funcs.playSound("Fire", gunInfo.FiringPoint)
end

function funcs.handleReplicateFire(part: BasePart)
	funcs.playSound("Fire", part)
end

function funcs.reloadGun(gunInfo: GunUtil.GunInfo)
	if reloading then return end
	local state = stateTable[gunInfo.Tool]
	if state.SharedState.MagSize >= gunInfo.Config.GunConfig.MagSize then return end -- do not allow reload full mag
	if state.SharedState.AmmoSize <= 0 then return end -- do not allow reload if ammo is empty
	if state.Dirty then return end -- already pending reload
	reloading = true

	local reloadAnim = funcs.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder.Reload)
	reloadAnim:Play()

	cleaner:add(task.delay(gunInfo.Config.GunConfig.ReloadDuration, function()
		reloadRemote:FireServer(gunInfo.Tool)
		reloadAnim:Stop()
		reloading = false
		state.Dirty = true
		log:debug("Reload finished")
	end))

	guiController:startReload()

	-- sound
	funcs.playSound("Reload", gunInfo.AnimPart)
	replicateReloadRemote:FireServer()
	log:debug("Reloading gun...")
end

function funcs.handleReplicateReload(part: BasePart)
	funcs.playSound("Reload", part)
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

function funcs.resolveAnim(gunTool: Tool, anim: Animation): AnimationTrack
	return loadedAnims[gunTool][anim]
end

function funcs.hookBackpack(backpack: Backpack)
	for _, tool: Tool in ipairs(backpack:GetChildren()) do
		if not tool:IsA("Tool") then continue end
		funcs.handleGunAdded(tool)
	end
	backpack.ChildAdded:Connect(funcs.handleGunAdded)
end
funcs.hookBackpack(player.Backpack)

function funcs.updateCharacter(newCharacter: Model)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	funcs.hookBackpack(player.Backpack)
end
player.CharacterAdded:Connect(funcs.updateCharacter)

UserInputService.InputBegan:Connect(funcs.handleInput)
UserInputService.InputEnded:Connect(funcs.handleInputEnd)
setStateRemote.OnClientEvent:Connect(funcs.handleSetGunState)
replicateReloadRemote.OnClientEvent:Connect(funcs.handleReplicateReload)
replicateFireRemote.OnClientEvent:Connect(funcs.handleReplicateFire)
