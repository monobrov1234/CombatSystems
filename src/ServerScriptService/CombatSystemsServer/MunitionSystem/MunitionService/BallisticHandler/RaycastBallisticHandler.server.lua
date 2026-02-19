--!strict

local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.MunitionService)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local RayTypeService = require(script.Parent.Parent.RayTypeService)

-- ROBLOX OBJECTS
local fireMunitionRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunition
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunition

-- FINALS
local _log: Logger.SelfObject = Logger.new("RaycastBallisticHandlerServer")

-- raycast munition handler
function funcs.handleFireMunitionRaycast(player: Player, rayRequest: MunitionRayInfo.ClientRequest, hit: MunitionRayHitInfo.Common)	
	-- initial validation
	RayTypeService.validatePlayerRayRequest(player, rayRequest)
	RayTypeService.validatePlayerRayHit(player, hit)

	local rayNonValid: RayTypeService.RayInfoNonValid = RayTypeService.convertPlayerRayInfoToNonValid(player, rayRequest)
	assert(not rayNonValid.MunitionConfig.EnableBallistics) -- smoke check: raycast munitions must have ballistics disabled

	-- validate fire
	local serverRay: RayTypeService.RayInfo = MunitionService.validateRayFire(rayNonValid)
	-- process fire
	MunitionService.processMunitionFire(serverRay)

	if hit.Hit then
		-- validate hit
		MunitionService.validateRayHit(serverRay, hit)
		-- process hit
		MunitionService.processMunitionHit(serverRay, hit)
	end

	-- replicate fire
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicationRemote:FireClient(pl, hit)
	end
end

fireMunitionRemote.OnServerEvent:Connect(funcs.handleFireMunitionRaycast)