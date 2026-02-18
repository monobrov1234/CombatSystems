local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)

MunitionController.RayEnded:connect(function(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common)
	if ray.MunitionConfig.MunitionName ~= script.Parent.Name then return end
	if not hit.Hit then return end

	-- slopcode directly from trek, TODO: rewrite
	local theparticles = script.SmallExplosion:Clone()
	theparticles.Position = hit.HitPos
	theparticles.Parent = GunSystemConfig.ProjectileFolder
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
