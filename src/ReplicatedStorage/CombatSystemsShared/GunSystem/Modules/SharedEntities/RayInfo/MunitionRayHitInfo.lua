--!strict

-- IMPORTS
local MunitionRayInfo = require(script.Parent.MunitionRayInfo)

export type ClientType = {
	RayInfo: MunitionRayInfo.ClientType,
	HitPos: Vector3,
	Hit: BasePart?
}

return {}