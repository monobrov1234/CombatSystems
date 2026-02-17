--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local BoundsUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.BoundsUtilModule)
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
module.DirectHit = Signal.new() -- (rayHitInfo: MunitionRayHitInfo.Type)
module.ExplosionHit = Signal.new() -- (rayHitInfo: MunitionRayHitInfo.Type, hits: { ExplosionHitInfo })

function funcs.handleHit(rayHitInfo: RayTypeService.RayHitInfoValid)
	if not rayHitInfo.Hit or not rayHitInfo.Hit:IsA("BasePart") then return end
	local config = rayHitInfo.RayInfo.MunitionConfig
	local explosionConfig = config.ExplosionConfig
	if explosionConfig.CanExplode then
		module.ExplosionHit:fire(rayHitInfo, funcs.calculateExplosionHits(rayHitInfo))
	end

	module.DirectHit:fire(rayHitInfo)
end

function funcs.calculateExplosionHits(rayHitInfo: RayTypeService.RayHitInfoValid): ExplosionHits
	local config = rayHitInfo.RayInfo.MunitionConfig
	local explosionConfig = config.ExplosionConfig

    local totalRadius = explosionConfig.Radius * 2
    local size = Vector3.new(totalRadius, totalRadius, totalRadius)

    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = rayHitInfo.RayInfo.RaycastParams.FilterDescendantsInstances

    local hits: ExplosionHits = {}
    local boxParts: { BasePart } = workspace:GetPartBoundsInBox(CFrame.new(rayHitInfo.HitPos), size, overlapParams)
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

    return hits
end

MunitionService.PreHit:connect(funcs.handleHit)

return module