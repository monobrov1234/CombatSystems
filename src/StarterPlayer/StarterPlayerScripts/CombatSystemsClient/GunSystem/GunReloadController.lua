--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local _player = Players.LocalPlayer :: Player
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.GunSystemConfig)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)
local SoundUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.SoundUtil)

-- IMPORTS INTERNAL
local BackpackController = require(script.Parent.BackpackController)

-- ROBLOX OBJECTS
-- C->S
local reloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.Core.ClientToServer.ReloadGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.Core.ReplicateReloadGun

-- FINALS
local log: Logger.SelfObject = Logger.new("GunReloadController")
local cleaner = ConnectionCleaner.new()

-- STATE
local gunInfo: GunUtil.GunInfo?
local reloading = false

-- PUBLIC EVENTS
module.ReloadStarted = Signal.new()

-- PUBLIC API
function module.tryReloadGun()
	if not gunInfo then return end
	if reloading then return end

	local state: BackpackController.GunState? = BackpackController.getStateFor(gunInfo.Tool)
	assert(state)
	if state.SharedState.MagSize >= gunInfo.Config.MagSize then return end
	if state.SharedState.AmmoSize <= 0 then return end
	if state.Dirty then return end
	reloading = true

	local reloadAnim = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("Reload"))
	assert(reloadAnim, "No reload anim for gun " .. gunInfo.Tool.Name)
	reloadAnim:Play()

	cleaner:add(task.delay(gunInfo.Config.ReloadDuration, function()
		reloadRemote:FireServer(gunInfo.Tool)
		reloadAnim:Stop()
		reloading = false
		state.Dirty = true
		log:debug("Reload finished")
	end))

	SoundUtil.play("Reload", gunInfo.AnimPart)
	replicateReloadRemote:FireServer()

	module.ReloadStarted:fire(gunInfo.Config.ReloadDuration)
	log:debug("Reloading gun...")
end

function module.isReloading(): boolean
	return reloading
end

-- INTERNAL FUNCTIONS
function funcs.handleGunEquipped(newGunInfo: GunUtil.GunInfo)
	gunInfo = newGunInfo
end

function funcs.handleGunUnequipped()
	cleaner:disconnectAll()
	reloading = false
	gunInfo = nil
end

function funcs.handleInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not gunInfo then return end
	
	local equipped = BackpackController.getEquippedGun()
	if not equipped or equipped.Tool ~= gunInfo.Tool then return end

	if input.KeyCode == GunSystemConfig.KeyBindings.ReloadKey then
		module.tryReloadGun()
	end
end

function funcs.handleReplicateReload(part: BasePart)
	SoundUtil.play("Reload", part)
end

-- SUBSCRIPTIONS
UserInputService.InputBegan:Connect(funcs.handleInputBegan)
BackpackController.GunEquipped:connect(funcs.handleGunEquipped)
BackpackController.GunUnequipped:connect(funcs.handleGunUnequipped)
replicateReloadRemote.OnClientEvent:Connect(funcs.handleReplicateReload)

return module
