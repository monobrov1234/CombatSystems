--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local BoundsUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.BoundsUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)

-- IMPORTS INTERNAL
local MunitionService = require(script.Parent.MunitionServiceModule)
local RayTypeService = require(script.Parent.RayTypeServiceModule)

-- FINALS
local _log: Logger.SelfObject = Logger.new("MunitionHitService")

export type ExplosionHitInfo = {
	Part: BasePart,
	ClosestBoundsDistance: number,
}
export type ExplosionHits = { ExplosionHitInfo }

-- PUBLIC EVENTS
module.DirectHit = Signal.new() -- (ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.CommonFull)
module.ExplosionHit = Signal.new() -- (ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.CommonFull, hits: { ExplosionHitInfo })

function funcs.handleHit(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.CommonFull)
	if not hit.Hit then return end
	if ray.MunitionConfig.ExplosionConfig.CanExplode then
		module.ExplosionHit:fire(ray, hit, funcs.calculateExplosionHits(ray, hit))
	end

	module.DirectHit:fire(ray, hit)
end

function funcs.calculateExplosionHits(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.CommonFull): ExplosionHits
	local config = ray.MunitionConfig
	local explosionConfig = config.ExplosionConfig

    local totalRadius = explosionConfig.Radius * 2
    local size = Vector3.new(totalRadius, totalRadius, totalRadius)

    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = ray.RaycastParams.FilterDescendantsInstances

    local hits: ExplosionHits = {}
    local boxParts: { BasePart } = workspace:GetPartBoundsInBox(CFrame.new(hit.HitPos), size, overlapParams)
    for _, part: BasePart in ipairs(boxParts) do
        table.insert(
            hits,
            {
                Part = part,
                ClosestBoundsDistance = BoundsUtil.distanceToPartBounds(hit.HitPos, part),
            } :: ExplosionHitInfo
        )
    end

    -- sort by distance; closest first, farthest last
    table.sort(hits, function(a: ExplosionHitInfo, b: ExplosionHitInfo)
        return a.ClosestBoundsDistance < b.ClosestBoundsDistance
    end)

    return hits
end

MunitionService.PreHit:connect(funcs.handleHit)

return module