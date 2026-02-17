--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local RayTypeService = require(script.Parent.RayTypeServiceModule)

-- ROBLOX OBJECTS
local fireMunitionRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunition
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunition
local fireMunitionBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.FireMunitionBallistic
local verifyHitBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ClientToServer.VerifyHitBallistic
local replicationBallisticRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.MunitionService.ServerToClient.ReplicateFireMunitionBallistic

-- FINALS

local log: Logger.SelfObject = Logger.new("MunitionService")

type RayCacheInfo = {
	RayInfo: RayTypeService.RayInfoValid,
	CreationTime: number,
}
-- fastcast ray cache, used to track existing flying munitions
local rayCache: { [string]: RayCacheInfo } = {}
local rayCacheLivingTime = 10 -- max ray living time in rayCache table

-- validator pipeline, these functions should validate shooting if it is performed from their services weapons
-- if one validator fails, then fire will not be registered
-- validators should throw an exception if they fail
type ValidatorCallback = (rayInfo: RayTypeService.RayInfoNonValid) -> (RaycastParams?)
local validatorPipeline = {} :: { ValidatorCallback }

-- PUBLIC EVENTS

-- called when player munition is validated and fully permitted, used by other services for example to update mag size and ammo
module.FireMunition = Signal.new() -- (rayInfo: MunitionRayInfo.Type)
-- called before determining hit type and calculating specifics (e.g explosion hit list)
-- mainly for use in MunitionHitService
module.PreHit = Signal.new() -- (rayHitInfo: MunitionRayHitInfo.Type)

-- PUBLIC API
function module.registerFireValidator(validator: ValidatorCallback)
	table.insert(validatorPipeline, validator)
end

-- INTERNAL FUNCTIONS

-- garbage collector for fastcast ray table
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

function funcs.validateFire(rayInfo: RayTypeService.RayInfoNonValid): RaycastParams
	local raycastParams: RaycastParams?
	for _, callback: ValidatorCallback in ipairs(validatorPipeline) do
		raycastParams = callback(rayInfo)
		if raycastParams then break end
	end

	-- if every validator not failed but returned nil it probably means that player isn't holding anything but tried to call shooting event
	-- it also could be programmer error if there is no validator registered for their service
	assert(raycastParams, "Player is not using any weapon")
	return raycastParams
end

-- raycast munition handler
function funcs.handleFireMunitionRaycast(player: Player, rayHitInfo: MunitionRayHitInfo.ClientType)
	-- initial validation
	RayTypeService.validateClientRayHitInfo(player, rayHitInfo)
	local rayHitInfoNonValid: RayTypeService.RayHitInfoNonValid = RayTypeService.convertClientRayHitInfoToNonValid(player, rayHitInfo)
	local rayInfoNonValid: RayTypeService.RayInfoNonValid = rayHitInfoNonValid.RayInfo
	assert(not rayInfoNonValid.MunitionConfig.EnableBallistics) -- smoke check: raycast munitions must have ballistics disabled

	-- validate fire
	local raycastParams: RaycastParams = funcs.validateFire(rayInfoNonValid)

	-- process fire
	local rayHitInfoServer: RayTypeService.RayHitInfoValid = RayTypeService.convertNonValidRayHitInfoToServer(rayHitInfoNonValid, raycastParams)
	module.FireMunition:fire(rayHitInfoServer)

	-- replicate fire
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicationRemote:FireClient(pl, rayHitInfo)
	end

	-- process hit
	-- TODO: additional hitreg anticheat
	if rayHitInfo.Hit then
		module.PreHit:fire(rayHitInfoServer.RayInfo)
	end
end

-- fastcast munition handler
function funcs.handleFireMunitionBallistic(player: Player, rayInfo: MunitionRayInfo.ClientType)
	-- initial validation
	RayTypeService.validateClientRayInfo(player, rayInfo)
	assert(not rayCache[rayInfo.RayId]) -- check if that ray id already exists
	local rayInfoNonValid: RayTypeService.RayInfoNonValid = RayTypeService.convertClientRayInfoToNonValid(player, rayInfo)
	local config: MunitionConfigUtil.DefaultType = rayInfoNonValid.MunitionConfig
	assert(config.EnableBallistics) -- smoke check: ballistic munitions must have ballistics enabled

	-- validate fire
	local raycastParams: RaycastParams = funcs.validateFire(rayInfoNonValid)

	-- process fire and save RayId
	local rayInfoValid: RayTypeService.RayInfoValid = RayTypeService.convertNonValidRayInfoToServer(rayInfoNonValid, raycastParams)
	module.FireMunition:fire(rayInfoValid)

	rayCache[rayInfo.RayId] = {
		RayInfo = rayInfoValid,
		CreationTime = os.clock(),
	}

	-- replicate fire
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicationBallisticRemote:FireClient(pl, rayInfo)
	end

	log:debug("Saved & Replicated munition {} rayId {}", config.MunitionName, rayInfo.RayId)
end

-- no anticheat for verifying ballistic munitions for now; too complex to implement
-- server-side tracing will cause issues for players with high latency
function funcs.handleVerifyHitBallistic(player: Player, rayId: string, hitPos: Vector3, hit: BasePart?)
	-- initial validation
	assert(typeof(rayId) == "string"
			and typeof(hitPos) == "Vector3")
	if hit then
		assert(typeof(hit) == "Instance" 
			and hit:IsA("BasePart"))
	end

	-- validate ray exists
	local rayCacheInfo: RayCacheInfo = rayCache[rayId]
	assert(rayCacheInfo and rayCacheInfo.RayInfo.Player == player)
	rayCache[rayId] = nil

	-- process hit
	if hit then
		local rayHitInfoValid: RayTypeService.RayHitInfoValid = {
			RayInfo = rayCacheInfo.RayInfo,
			HitPos = hitPos,
			Hit = hit
		}
		module.PreHit:fire(rayHitInfoValid) 
	end

	log:debug("Verify hit called for munition {} rayId {}", rayCacheInfo.RayInfo.MunitionConfig.MunitionName, rayId)
end

fireMunitionRemote.OnServerEvent:Connect(funcs.handleFireMunitionRaycast)
fireMunitionBallisticRemote.OnServerEvent:Connect(funcs.handleFireMunitionBallistic)
verifyHitBallisticRemote.OnServerEvent:Connect(funcs.handleVerifyHitBallistic)
task.spawn(funcs.rayCacheGC)

return module
