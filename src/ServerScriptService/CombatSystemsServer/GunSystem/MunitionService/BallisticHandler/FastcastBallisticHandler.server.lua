--!strict

local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionServiceModule)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local RayTypeService = require(script.Parent.Parent.RayTypeServiceModule)

-- ROBLOX OBJECTS
local fireMunitionBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunitionBallistic
local verifyHitBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.VerifyHitBallistic
local replicationBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunitionBallistic

-- FINALS
local log: Logger.SelfObject = Logger.new("FastcastBallisticHandler")

type RayCacheInfo = {
	FireRayInfo: RayTypeService.RayInfo,
	CreationTime: number,
}
local rayCache: { [string]: RayCacheInfo } = {} -- ray cache, used to track existing flying munitions
local rayCacheLivingTime = 10 -- max ray living time in rayCache table

-- INTERNAL FUNCTIONS

-- fastcast munition handler
function funcs.handleFireMunitionBallistic(player: Player, rayInfo: MunitionRayInfo.ClientRequest)
	-- initial validation
	RayTypeService.validateClientRayInfo(player, rayInfo)
	local rayInfoNonValid: RayTypeService.RayInfoNonValid = RayTypeService.convertClientRayInfoToNonValid(player, rayInfo)

	local config: MunitionConfigUtil.DefaultType = rayInfoNonValid.MunitionConfig
	assert(config.EnableBallistics) -- smoke check: ballistic munitions must have ballistics enabled
	assert(not rayCache[rayInfo.RayId]) -- check if that ray id already exists

	-- validate fire
    local fireRay: RayTypeService.RayInfo = MunitionService.validateRayFire(rayInfoNonValid)

	-- process fire and save RayId
	MunitionService.processMunitionFire(fireRay)
	rayCache[rayInfo.RayId] = {
		FireRayInfo = fireRay,
		CreationTime = os.clock(),
	}

	-- replicate fire
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicationBallisticRemote:FireClient(pl, rayInfo)
	end

	log:debug("Saved & Replicated munition {} rayId {}", config.MunitionName, rayInfo.RayId)
end

-- TODO: server-side validation of ballistic munitions trajectories and hits
function funcs.handleVerifyHitBallistic(player: Player, rayId: string, hitPos: Vector3, hit: BasePart?)
	if not hit then return end -- TODO

	-- initial validation
	assert(typeof(rayId) == "string" and typeof(hitPos) == "Vector3")
	if hit then
		assert(typeof(hit) == "Instance" and hit:IsA("BasePart"))
	end

	-- validate that rayId exists
	local rayCacheInfo: RayCacheInfo = rayCache[rayId]
	assert(rayCacheInfo and rayCacheInfo.FireRayInfo.Player == player)
	rayCache[rayId] = nil

	-- validate hit
	local hitRayValid: RayTypeService.RayHitInfo = MunitionService.validateRayHit(rayCacheInfo.FireRayInfo, hitPos, hit)

	-- process hit
	MunitionService.processMunitionHit(hitRayValid)

	log:debug("Verify hit called for munition {} rayId {}", rayCacheInfo.FireRayInfo.MunitionConfig.MunitionName, rayId)
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