--!strict

local funcs = {}
local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurretStateService = require(script.Parent.TurretStateService)
local MunitionService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.MunitionService)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)

-- ROBLOX OBJECTS
-- S->C
local replicateFireSoundRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ServerToClient.ReplicateFireSound

-- INTERNAL FUNCTIONS
-- handles turret fire when it is validated
function funcs.handleTurretFire(rayInfo: RayTypeService.RayInfo)
	local player: Player? = rayInfo.Player
	if not player then return end
	local character: Model? = player.Character
	if not character then return end

	local turretInfo: TurretUtil.TurretInfo? = TurretStateService.getPlayerCurrentTurret(player)
	if not turretInfo then return end
	local stateInfo = TurretStateService.getTurretState(turretInfo)
	assert(stateInfo)

	local munitionName = rayInfo.MunitionConfig.MunitionName
	if stateInfo.UsingMainGun then
		assert(stateInfo.ClipSizeStorage[munitionName] > 0)
		stateInfo.ClipSizeStorage[munitionName] -= 1
	else
		assert(stateInfo.CoaxClipSize > 0)
		stateInfo.CoaxClipSize -= 1
	end

	-- replicate fire sound
	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicateFireSoundRemote:FireClient(pl, stateInfo.UsingMainGun and turretInfo.FiringPoint or turretInfo.FiringPointCoax, stateInfo.UsingMainGun)
	end
end

-- SUBSCRIPTIONS
MunitionService.FireMunition:connect(funcs.handleTurretFire)

return module