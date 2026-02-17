local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo))

MunitionController.RayEnded:connect(function(rayHitInfo: MunitionRayHitInfo.Type)
	local rayInfo = rayHitInfo.RayInfo
	if rayInfo.MunitionConfig.MunitionName ~= script.Parent.Name then return end
	if not rayHitInfo.Hit then return end

	-- shitcode directly from trek
	local theparticles = script.Standard:Clone()
	theparticles.Position = rayHitInfo.HitPos
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
