--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackController = require(script.Parent.BackpackController)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local MunitionSystemConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.MunitionSystemConfig)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- IMPORTS INTERNAL
local CursorController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.ClientFX.CursorController)

-- FINALS
local log: Logger.SelfObject = Logger.new("GunController")

-- STATE
local raycastParams: RaycastParams?

-- PUBLIC API
function module.getRaycastParams(): RaycastParams?
	return raycastParams
end

-- INTERNAL FUNCTIONS
function funcs.handleBackpackGunEquipped(gunInfo: GunUtil.GunInfo)
	raycastParams = funcs.buildRaycastParams(gunInfo)
	CursorController.enableCursor()
	log:debug("Client gun equipped: {}", gunInfo.Tool.Name)
end

function funcs.handleBackpackGunUnequipped(gunInfo: GunUtil.GunInfo)
	raycastParams = nil
	CursorController.disableCursor()
	log:debug("Client gun unequipped: {}", gunInfo.Tool.Name)
end

function funcs.buildRaycastParams(gunInfo: GunUtil.GunInfo): RaycastParams
	local character: Model? = player.Character
	assert(character)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, gunInfo.Tool, MunitionSystemConfig.ProjectileFolder }
	return params
end

BackpackController.GunEquipped:connect(funcs.handleBackpackGunEquipped, Signal.Priority.HIGH)
BackpackController.GunUnequipped:connect(funcs.handleBackpackGunUnequipped, Signal.Priority.HIGH)

return module
