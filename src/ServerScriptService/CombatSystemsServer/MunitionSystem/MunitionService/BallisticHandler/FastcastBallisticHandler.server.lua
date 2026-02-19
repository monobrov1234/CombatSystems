--!strict

local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.MunitionService)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local RayTypeService = require(script.Parent.Parent.RayTypeService)

-- ROBLOX OBJECTS
local fireMunitionBallisticRemote = ReplicatedStorage.CombatSystemsShared.MunitionSystem.Events.Core.ClientToServer.FireMunitionBallistic
local verifyHitBallisticRemote = ReplicatedStorage.CombatSystemsShared.MunitionSystem.Events.Core.ClientToServer.VerifyHitBallistic
local replicationBallisticRemote = ReplicatedStorage.CombatSystemsShared.MunitionSystem.Events.Core.ServerToClient.ReplicateFireMunitionBallistic

-- FINALS
local log: Logger.SelfObject = Logger.new("FastcastBallisticHandlerServer")

type RayCacheInfo = {
	Ray: RayTypeService.RayInfo,
	CreationTime: number,
}
local rayCache: { [string]: RayCacheInfo } = {} -- ray cache, used to track existing flying munitions
local rayCacheLivingTime = 10 -- max ray living time in rayCache table

-- INTERNAL FUNCTIONS

-- fastcast munition handler
function funcs.handleFireMunitionBallistic(player: Player, rayRequest: MunitionRayInfo.ClientRequest)
	-- initial validation
	RayTypeService.validatePlayerRayRequest(player, rayRequest)
	local rayInfoNonValid: RayTypeService.RayInfoNonValid = RayTypeService.convertPlayerRayInfoToNonValid(player, rayRequest)

	local config: MunitionConfigUtil.DefaultType = rayInfoNonValid.MunitionConfig
	assert(config.EnableBallistics) -- smoke check: ballistic munitions must have ballistics enabled
	assert(not rayCache[rayRequest.RayId]) -- check if that ray id already exists

	-- validate fire
    local serverRay: RayTypeService.RayInfo = MunitionService.validateRayFire(rayInfoNonValid)

	-- process fire and save RayId
	MunitionService.processMunitionFire(serverRay)
	rayCache[rayRequest.RayId] = {
		Ray = serverRay,
		CreationTime = os.clock(),
	}

	-- replicate fire
	local replicatedRay: MunitionRayInfo.ServerReplication = {
		Player = player,
		Team = player.Team,
		RayId = rayRequest.RayId,
		MunitionName = config.MunitionName,
		Origin = rayRequest.Origin,
		Body = rayRequest.Body
	}
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicationBallisticRemote:FireClient(pl, replicatedRay)
	end

	log:trace("Saved & Replicated munition {} rayId {}", config.MunitionName, rayRequest.RayId)
end

-- TODO: server-side validation of ballistic munitions trajectories and hits
function funcs.handleVerifyHitBallistic(player: Player, rayId: string, hit: MunitionRayHitInfo.Common)
	if not hit.Hit then return end -- TODO

	-- initial validation
	assert(typeof(rayId) == "string")
	RayTypeService.validatePlayerRayHit(player, hit)

	-- validate that the rayId is present
	local cached: RayCacheInfo = rayCache[rayId]
	assert(cached and cached.Ray.Player == player)
	rayCache[rayId] = nil

	-- validate hit
	MunitionService.validateRayHit(cached.Ray, hit)

	-- process hit
	MunitionService.processMunitionHit(cached.Ray, hit)

	log:trace("Verify hit called for munition {} rayId {}", cached.Ray.MunitionConfig.MunitionName, rayId)
end

-- garbage collector for the ray cache table
function funcs.rayCacheGC()
	while true do
		local toDelete: { string } = {}
		for rayID, rayInfo in pairs(rayCache) do
			if os.clock() - rayInfo.CreationTime > rayCacheLivingTime then
				table.insert(toDelete, rayID)
			end
		end

		for _, rayID in ipairs(toDelete) do
			rayCache[rayID] = nil
		end

		task.wait(0.5)
	end
end

fireMunitionBallisticRemote.OnServerEvent:Connect(funcs.handleFireMunitionBallistic)
verifyHitBallisticRemote.OnServerEvent:Connect(funcs.handleVerifyHitBallistic)
task.spawn(funcs.rayCacheGC)