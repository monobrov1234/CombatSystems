--!strict

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type RayInfo = typeof(require(script.Parent.RayInfo.MunitionRayInfo))

return {} :: {
	RayInfo: RayInfo,
	HitPos: Vector3,
	Hit: BasePart?,
}
