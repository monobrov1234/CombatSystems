--!nonstrict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionControllerModule)

-- FINALS
export type Config = {
	Color: ColorSequence,
}

MunitionController.RayEnded:connect(function(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common)
	local handler = ray.MunitionConfig.FXConfig.ImpactFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	-- this is from trek
	local config = handler.HandlerConfig :: Config
	local particle = script.Particle:Clone()
	particle.Position = hit.HitPos
	particle.Parent = GunSystemConfig.ProjectileFolder

	local random = math.random(1, 2)
	particle:FindFirstChild("impact" .. tostring(random)):Play()

	for i, child: ParticleEmitter in pairs(particle:GetChildren()) do
		if not child:IsA("ParticleEmitter") then continue end
		child.Color = config.Color
		child:Emit(child:FindFirstChild("EmitSize") and child.EmitSize.Value)
	end

	Debris:AddItem(particle, 10)
end)

return module
