local module = {}

if game:GetService("RunService"):IsServer() then return module end

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionController)
local MunitionSystemConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.MunitionSystemConfig)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)

MunitionController.RayEnded:connect(function(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common)
	local handler = ray.MunitionConfig.FXConfig.ImpactFXHandler
	if not handler or handler.HandlerModuleName ~= "HEImpactFXHandler" then return end
	if not hit.Hit then return end

	-- slopcode directly from trek, TODO: rewrite
	local theparticles = script.SmallExplosion:Clone()
	theparticles.Position = hit.HitPos
	theparticles.Parent = MunitionSystemConfig.ProjectileFolder
	theparticles:FindFirstChildOfClass("Sound"):Play()

	for i, v in pairs(theparticles:GetChildren()) do
		if not v:IsA("ParticleEmitter") then continue end
		v:Emit((v:FindFirstChild("EmitSize") and v.EmitSize.Value))
	end

	task.delay(10, function()
		if theparticles then theparticles:Destroy() end
	end)
end)

return module
