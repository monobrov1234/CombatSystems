--!strict

local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionServiceModule)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local RayTypeService = require(script.Parent.Parent.RayTypeServiceModule)

-- ROBLOX OBJECTS
local fireMunitionRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunition
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunition

-- FINALS
local _log: Logger.SelfObject = Logger.new("RaycastBallisticHandler")

-- raycast munition handler
function funcs.handleFireMunitionRaycast(player: Player, rayHitInfo: MunitionRayHitInfo.ClientRequest)	
	-- initial validation
	RayTypeService.validateClientRayHitInfo(player, rayHitInfo)
	local fireRayNonValid: RayTypeService.RayInfoNonValid = RayTypeService.convertClientRayInfoToNonValid(player, rayHitInfo.RayInfo)
	assert(not fireRayNonValid.MunitionConfig.EnableBallistics) -- smoke check: raycast munitions must have ballistics disabled

	-- validate fire
	local fireRay: RayTypeService.RayInfo = MunitionService.validateRayFire(fireRayNonValid)
	-- process fire
	MunitionService.processMunitionFire(fireRay)

	if rayHitInfo.Hit then
		-- validate hit
		local hitRay: RayTypeService.RayHitInfo = MunitionService.validateRayHit(fireRay, rayHitInfo.HitPos, rayHitInfo.Hit)
		-- process hit
		MunitionService.processMunitionHit(hitRay)
	end

	-- replicate fire
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicationRemote:FireClient(pl, rayHitInfo)
	end
end

fireMunitionRemote.OnServerEvent:Connect(funcs.handleFireMunitionRaycast)