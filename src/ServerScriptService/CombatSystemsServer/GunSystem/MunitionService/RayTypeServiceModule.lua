--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)

-- TYPES
export type RayInfoNonValid = {
	Player: Player?,
	Team: Team?,
	RayId: string,
	MunitionConfig: MunitionConfigUtil.DefaultType,
	Origin: BasePart,
	Body: MunitionRayInfo.Common
}

export type RayInfo = RayInfoNonValid & {
	RaycastParams: RaycastParams,
}

-- PUBLIC API
function module.convertNonValidRayInfoToServer(rayInfo: RayInfoNonValid, raycastParams: RaycastParams): RayInfo
	return { 
		Player = rayInfo.Player,
		Team = rayInfo.Team,
		RayId = rayInfo.RayId,
		MunitionConfig = rayInfo.MunitionConfig,
		Origin = rayInfo.Origin,
		Body = rayInfo.Body,
		RaycastParams = raycastParams
	}
end

function module.convertPlayerRayInfoToNonValid(player: Player, rayInfo: MunitionRayInfo.ClientRequest): RayInfoNonValid
	local resolvedConfig: MunitionConfigUtil.DefaultType? = MunitionConfigUtil.getConfig(rayInfo.MunitionName)
	assert(resolvedConfig)

	return {
		Player = player,
		Team = player.Team,
		RayId = rayInfo.RayId,
		MunitionConfig = resolvedConfig,
		Origin = rayInfo.Origin,
		Body = rayInfo.Body
	}
end

function module.validatePlayerRayHit(player: Player, hit: MunitionRayHitInfo.Common)
	assert(typeof(hit) == "table")
	assert(typeof(hit.HitPos) == "Vector3")
	if hit.Hit then 
		assert(typeof(hit.Hit) == "Instance" and hit.Hit:IsA("BasePart")) 
	end
end

function module.validatePlayerRayRequest(player: Player, rayInfo: MunitionRayInfo.ClientRequest)
	assert(typeof(rayInfo) == "table")
	assert(typeof(rayInfo.RayId) == "string"
			and typeof(rayInfo.MunitionName) == "string"
			and typeof(rayInfo.Origin) == "Instance"
			and typeof(rayInfo.Body) == "table"
			and typeof(rayInfo.Body.InitOriginPos) == "Vector3"
			and typeof(rayInfo.Body.InitDirection) == "Vector3")
	assert(rayInfo.Origin:IsA("BasePart"))
end

return module