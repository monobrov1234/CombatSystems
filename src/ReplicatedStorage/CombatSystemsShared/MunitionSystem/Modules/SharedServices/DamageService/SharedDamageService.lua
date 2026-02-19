--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)

-- FINALS
export type DamageHandler = {
    canDamageHit: (shooter: Player?, shooterTeam: Team?, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType) -> boolean,
    calculateDirectDamage: (ray: MunitionRayInfo.Common, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType) -> number?
}
local damageHandlerPipeline = {} :: { DamageHandler }

-- PUBLIC API
function module.canDamageHit(shooter: Player?, shooterTeam: Team?, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType): boolean
    for _, handler: DamageHandler in ipairs(damageHandlerPipeline) do
        if not handler.canDamageHit(shooter, shooterTeam, hit, config) then
            return false
        end
    end

    return true
end

function module.calculateDirectDamage(ray: MunitionRayInfo.Common, hit: MunitionRayHitInfo.CommonFull, config: MunitionConfigUtil.DefaultType): number
    for _, handler: DamageHandler in ipairs(damageHandlerPipeline) do
        local resolvedDamage: number? = handler.calculateDirectDamage(ray, hit, config)
        if resolvedDamage ~= nil then
            return resolvedDamage
        end
    end

    return 0
end

function module.registerDamageHandler(handler: DamageHandler)
    table.insert(damageHandlerPipeline, handler)
end

return module
