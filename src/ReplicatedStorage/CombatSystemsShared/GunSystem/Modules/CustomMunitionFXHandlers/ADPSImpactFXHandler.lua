local module = {}
local funcs = {}

if game:GetService("RunService"):IsServer() then return module end

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)

function funcs.handleRayEnded(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common)
	local handler = ray.MunitionConfig.FXConfig.ImpactFXHandler
	if not handler or handler.HandlerModuleName ~= "APDSImpactFXHandler" then return end
	if not hit.Hit then return end

	local rng = Random.new()
	local root = script.ImpactEffect:Clone()

	local originPos = (ray.Origin and ray.Origin.Position) or ray.Body.InitOriginPos
	local direction = (originPos - hit.HitPos).Unit
	root.CFrame = CFrame.lookAt(hit.HitPos, hit.HitPos + direction)
	root.Parent = GunSystemConfig.ProjectileFolder

	local uplift = Vector3.new(0, 1, 0)
	local baseDir = (direction + uplift).Unit

	for i = 1, 20 do
		local shard = script.Shard:Clone()
		shard.CanTouch = false
		shard.CanQuery = false
		shard.CFrame = CFrame.new(hit.HitPos)
		shard.Parent = GunSystemConfig.ProjectileFolder

		local dir = funcs.randomHemisphereDirection(rng, baseDir)
		shard.AssemblyLinearVelocity = dir * rng:NextNumber(50, 80)
		shard.AssemblyAngularVelocity = Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(-10, 10), rng:NextNumber(-10, 10))

		Debris:AddItem(shard, 1.5)
	end

	task.delay(0.05, function()
		root.Attachment.Smoke:Emit(18)
		root.Attachment.Sparks:Emit(10)
	end)

	Debris:AddItem(root, 2)
end

function funcs.randomHemisphereDirection(rng: Random, baseDir: Vector3): Vector3
	local v
	repeat
		v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
	until v.Magnitude > 0.001

	v = v.Unit
	if v:Dot(baseDir) < 0 then v = -v end

	return v
end

MunitionController.RayEnded:connect(funcs.handleRayEnded)

return module
