--!strict

-- IMPORTS
local MunitionRayInfo = require(script.Parent.MunitionRayInfo)

export type ClientRequest = {
	RayInfo: MunitionRayInfo.ClientRequest,
	HitPos: Vector3,
	Hit: BasePart?
}

export type ServerReplication = {
	RayInfo: MunitionRayInfo.ServerReplication,
	HitPos: Vector3,
	Hit: BasePart?
}

return {}