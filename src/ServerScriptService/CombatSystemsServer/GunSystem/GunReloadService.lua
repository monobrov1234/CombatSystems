local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GunConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunConfigUtil)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)

-- IMPORTS INTERNAL
local GunStateService = require(script.Parent.GunStateService)

-- ROBLOX OBJECTS
-- S->C
local setStateRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.Core.ServerToClient.SetGunState
-- C->S
local reloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.Core.ClientToServer.ReloadGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.Core.ReplicateReloadGun

-- TODO: validate last shoot time
function funcs.handleGunReload(player: Player, gunTool: Tool)
	local character = player.Character
	if not character then return end
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool ~= gunTool then return end

	local config = GunConfigUtil.getConfig(gunTool.Name)
	assert(config)
	local state = GunStateService.getGunState(gunTool)
	assert(state)

	local ammoSize = state.SharedState.AmmoSize
	local magSize = state.SharedState.MagSize
	local neededAmmo = config.MagSize - magSize
	if ammoSize >= neededAmmo then
		state.SharedState.MagSize = config.MagSize
		state.SharedState.AmmoSize -= neededAmmo
	else
		state.SharedState.MagSize += ammoSize
		state.SharedState.AmmoSize = 0
	end

	setStateRemote:FireClient(player, gunTool, state.SharedState)
end

function funcs.handleReplicateReload(player: Player, gunTool: Tool)
	local character = player.Character
	if not character then return end
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool ~= gunTool then return end

	local gunInfo = GunUtil.parseGunInfo(gunTool)
	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicateReloadRemote:FireClient(pl, gunInfo.AnimPart)
	end
end

reloadRemote.OnServerEvent:Connect(funcs.handleGunReload)
replicateReloadRemote.OnServerEvent:Connect(funcs.handleReplicateReload)

return module
