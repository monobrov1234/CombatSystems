local module = {}

local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local BoundsUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.BoundsUtilModule)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo))

-- ROBLOX OBJECTS
local fireMunitionRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunition
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunition
local fireMunitionBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunitionBallistic
local verifyHitBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.VerifyHitBallistic
local replicationBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunitionBallistic

-- FINALS
local log: Logger.SelfObject = Logger.new("MunitionService")

type RayCacheInfo = {
	RayInfo: RayInfo,
	CreationTime: number,
}
local rayCache: { [string]: RayCacheInfo } = {}
local rayCacheLivingTime = 10 -- max ray living time in rayCache table

-- PUBLIC API
-- fire handler api
export type FireHandlerContext = {
	ResultRaycastParams: RaycastParams?,
}
module.ValidateFire = Signal.new()

-- hit handler api
export type ExplosionHitInfo = {
	Part: BasePart,
	ClosestBoundsDistance: number,
}
module.DirectHit = Signal.new()
module.ExplosionHit = Signal.new()

-- INTERNAL FUNCTIONS
function funcs.handleFire(rayInfo: RayInfo): RaycastParams?
	local context: FireHandlerContext = { ResultRaycastParams = nil }
	module.ValidateFire:fire(rayInfo, context)
	return context.ResultRaycastParams
end

function funcs.handleHit(rayHitInfo: RayHitInfo)
	if not rayHitInfo.Hit:IsA("BasePart") then return end

	debug.profilebegin("munitionHit")
	local rayInfo = rayHitInfo.RayInfo
	local config = rayHitInfo.RayInfo.MunitionConfig

	local explosionConfig = config.ExplosionConfig
	if explosionConfig.CanExplode then
		local totalRadius = explosionConfig.Radius * 2
		local size = Vector3.new(totalRadius, totalRadius, totalRadius)
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = rayInfo.RaycastParams.FilterDescendantsInstances
		local boxParts: { BasePart } = workspace:GetPartBoundsInBox(CFrame.new(rayHitInfo.HitPos), size, overlapParams)

		local hits: { ExplosionHitInfo } = {}
		for _, part: BasePart in ipairs(boxParts) do
			table.insert(
				hits,
				{
					Part = part,
					ClosestBoundsDistance = BoundsUtil.distanceToPartBounds(rayHitInfo.HitPos, part),
				} :: ExplosionHitInfo
			)
		end

		-- sort by distance, closest first, farthest last
		table.sort(hits, function(a: ExplosionHitInfo, b: ExplosionHitInfo)
			return a.ClosestBoundsDistance < b.ClosestBoundsDistance
		end)

		module.ExplosionHit:fire(rayHitInfo, hits)
	end

	module.DirectHit:fire(rayHitInfo)
	debug.profileend()
end

-- raycast munition handler
function funcs.handleFireMunition(player: Player, rayHitInfo: RayHitInfo)
	funcs.validateLoadRayHitInfo(player, rayHitInfo)
	local rayInfo: RayInfo = rayHitInfo.RayInfo
	local config: MunitionConfigUtil.DefaultType = rayInfo.MunitionConfig
	assert(not config.EnableBallistics)

	-- validate that player is in correct state to fire this munition, and returns raycast params
	local raycastParams = funcs.handleFire(rayInfo)
	-- if all handlers failed to validate, player is bugged or is exploiting
	assert(raycastParams)
	rayInfo.RaycastParams = raycastParams

	for _, pl in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicationRemote:FireClient(pl, rayHitInfo)
	end

	-- TODO: additional hitreg anticheat
	if rayHitInfo.Hit then funcs.handleHit(rayHitInfo) end
end

-- fastcast munition handler
function funcs.handleFireMunitionBallistic(player: Player, rayInfo: RayInfo)
	funcs.validateLoadRayInfo(player, rayInfo)
	assert(not rayCache[rayInfo.RayId])
	local config: MunitionConfigUtil.DefaultType = rayInfo.MunitionConfig
	assert(config.EnableBallistics)

	local raycastParams = funcs.handleFire(rayInfo)
	assert(raycastParams)
	rayInfo.RaycastParams = raycastParams

	rayCache[rayInfo.RayId] = {
		RayInfo = rayInfo,
		CreationTime = os.clock(),
	}

	for _, pl in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicationBallisticRemote:FireClient(pl, rayInfo)
	end

	log:debug("Saved & Replicated munition {} rayId {}", config.MunitionName, rayInfo.RayId)
end

-- no anticheat for verifying ballistic munitions for now; too complex to implement
-- server-side tracing will cause issues for players with high latency
function funcs.handleVerifyHitBallistic(player: Player, rayHitInfo: RayHitInfo)
	funcs.validateLoadRayHitInfo(player, rayHitInfo)
	local rayId = rayHitInfo.RayInfo.RayId
	local rayInfo: RayCacheInfo = rayCache[rayId]
	assert(rayInfo and rayInfo.RayInfo.Player == player)

	log:debug("Verify hit called for munition {} rayId {}", rayInfo.RayInfo.MunitionConfig.MunitionName, rayId)

	rayCache[rayId] = nil
	rayHitInfo.RayInfo = rayInfo.RayInfo

	if rayHitInfo.Hit then funcs.handleHit(rayHitInfo) end
end

function funcs.validateLoadRayHitInfo(player: Player, rayHitInfo: RayHitInfo)
	assert(typeof(rayHitInfo) == "table")
	assert(typeof(rayHitInfo.RayInfo) == "table" and typeof(rayHitInfo.HitPos) == "Vector3")
	if rayHitInfo.Hit then assert(typeof(rayHitInfo.Hit) == "Instance" and rayHitInfo.Hit:IsA("BasePart")) end
	funcs.validateLoadRayInfo(player, rayHitInfo.RayInfo)
end

function funcs.validateLoadRayInfo(player: Player, rayInfo: RayInfo)
	assert(typeof(rayInfo) == "table")
	assert(
		typeof(rayInfo.RayId) == "string"
			and typeof(rayInfo.MunitionConfig) == "table"
			and typeof(rayInfo.Origin) == "Instance"
			and typeof(rayInfo.InitOriginPos) == "Vector3"
			and typeof(rayInfo.InitDirection) == "Vector3"
	)
	assert(typeof(rayInfo.MunitionConfig.MunitionName) == "string")
	assert(rayInfo.Origin:IsA("BasePart"))

	if rayInfo.RaycastParams then assert(typeof(rayInfo.RaycastParams) == "RaycastParams") end

	local resolvedConfig = MunitionConfigUtil.getConfig(rayInfo.MunitionConfig.MunitionName)
	assert(resolvedConfig)
	rayInfo.MunitionConfig = resolvedConfig
	rayInfo.Player = player
	rayInfo.Team = player.Team
end

-- garbage collector for fastcast ray table
function funcs.rayCacheGC()
	while true do
		local toDelete: { string } = {}
		for rayID, rayInfo in pairs(rayCache) do
			if os.clock() - rayInfo.CreationTime > rayCacheLivingTime then table.insert(toDelete, rayID) end
		end

		for _, rayID in ipairs(toDelete) do
			rayCache[rayID] = nil
		end

		task.wait(0.5)
	end
end

task.spawn(funcs.rayCacheGC)
fireMunitionRemote.OnServerEvent:Connect(funcs.handleFireMunition)
fireMunitionBallisticRemote.OnServerEvent:Connect(funcs.handleFireMunitionBallistic)
verifyHitBallisticRemote.OnServerEvent:Connect(funcs.handleVerifyHitBallistic)

return module
