--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)

-- FINALS
export type RayInfoNonValid = {
	Player: Player?,
	Team: Team?,
	RayId: string,
	MunitionConfig: MunitionConfigUtil.DefaultType,
	Origin: BasePart,
	InitOriginPos: Vector3,
	InitDirection: Vector3,
}

export type RayInfoValid = RayInfoNonValid & {
	RaycastParams: RaycastParams,
}

type RayHitInfoBase = {
	HitPos: Vector3,
	Hit: BasePart?,
}

export type RayHitInfoNonValid = {
	RayInfo: RayInfoNonValid,
} & RayHitInfoBase

export type RayHitInfoValid = {
	RayInfo: RayInfoValid,
} & RayHitInfoBase

-- PUBLIC API
function module.convertNonValidRayHitInfoToServer(rayHitInfo: RayHitInfoNonValid, raycastParams: RaycastParams): RayHitInfoValid
	local rayInfoValidated: RayInfoValid = module.convertNonValidRayInfoToServer(rayHitInfo.RayInfo, raycastParams)
	return {
		RayInfo = rayInfoValidated,
		Hit = rayHitInfo.Hit,
		HitPos = rayHitInfo.HitPos
	}
end

function module.convertNonValidRayInfoToServer(rayInfo: RayInfoNonValid, raycastParams: RaycastParams): RayInfoValid
	return { 
		Player = rayInfo.Player,
		Team = rayInfo.Team,
		RayId = rayInfo.RayId,
		MunitionConfig = rayInfo.MunitionConfig,
		Origin = rayInfo.Origin,
		InitOriginPos = rayInfo.InitOriginPos,
		InitDirection = rayInfo.InitDirection,
		RaycastParams = raycastParams
	}
end

function module.convertClientRayHitInfoToNonValid(player: Player, rayHitInfo: MunitionRayHitInfo.ClientType): RayHitInfoNonValid
	local convertedRayInfo: RayInfoNonValid = module.convertClientRayInfoToNonValid(player, rayHitInfo.RayInfo)
	return {
		RayInfo = convertedRayInfo,
		Hit = rayHitInfo.Hit,
		HitPos = rayHitInfo.HitPos
	}
end

function module.convertClientRayInfoToNonValid(player: Player, rayInfo: MunitionRayInfo.ClientType): RayInfoNonValid
	local resolvedConfig: MunitionConfigUtil.DefaultType? = MunitionConfigUtil.getConfig(rayInfo.MunitionName)
	assert(resolvedConfig)

	return {
		Player = player,
		Team = player.Team,
		RayId = rayInfo.RayId,
		MunitionConfig = resolvedConfig,
		Origin = rayInfo.Origin,
		InitOriginPos = rayInfo.InitOriginPos,
		InitDirection = rayInfo.InitDirection,
	}
end

function module.validateClientRayHitInfo(player: Player, rayHitInfo: MunitionRayHitInfo.ClientType)
	assert(typeof(rayHitInfo) == "table")
	assert(typeof(rayHitInfo.RayInfo) == "table" and typeof(rayHitInfo.HitPos) == "Vector3")
	if rayHitInfo.Hit then 
		assert(typeof(rayHitInfo.Hit) == "Instance" and rayHitInfo.Hit:IsA("BasePart")) 
	end
end

function module.validateClientRayInfo(player: Player, rayInfo: MunitionRayInfo.ClientType)
	assert(typeof(rayInfo) == "table")
	assert(typeof(rayInfo.RayId) == "string"
			and typeof(rayInfo.MunitionName) == "string"
			and typeof(rayInfo.Origin) == "Instance"
			and typeof(rayInfo.InitOriginPos) == "Vector3"
			and typeof(rayInfo.InitDirection) == "Vector3")
	assert(rayInfo.Origin:IsA("BasePart"))
end

return module