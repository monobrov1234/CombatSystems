--!strict

-- when you don't have right arm you can't shoot guns but can use turrets
-- when you don't have left arm you can't reload guns but can use and reload turrets
-- when you don't have both arms you can't use guns nor turrets

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HumanoidHitHandler = require(script.Parent.HumanoidHitHandler)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)

local limbs: {string} = {"Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

-- INTERNAL FUNCTIONS
function funcs.handleHit(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.CommonFull, humanoid: Humanoid)
	if ray.MunitionConfig.LimbDestroyChance <= 0 then return end
	if not table.find(limbs, hit.Hit.Name) then return end
	if math.random(1, 100) > ray.MunitionConfig.LimbDestroyChance then return end

	for _, joint in hit.Hit:GetJoints() do
		joint:Destroy()
	end

    -- TODO: add screams and gfx
end

-- SUBSCRIPTIONS
HumanoidHitHandler.DirectHit:connect(funcs.handleHit)
HumanoidHitHandler.ExplosionHit:connect(funcs.handleHit)

return module
