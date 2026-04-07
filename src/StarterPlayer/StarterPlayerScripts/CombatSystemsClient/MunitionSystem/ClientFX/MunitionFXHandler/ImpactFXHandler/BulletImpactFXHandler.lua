--!nonstrict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local MunitionSystemConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.MunitionSystemConfig)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionController)

-- ROBLOX OBJECTS
local assets = ReplicatedStorage.CombatSystemsShared.MunitionSystem.Assets.ClientFXHandler.ImpactFXHandler[script.Name]

-- FINALS
export type Config = {
	Color: ColorSequence,
}

MunitionController.RayEnded:connect(function(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common)
	local handler = ray.MunitionConfig.FXConfig.ImpactFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	-- this is from trek
	local config = handler.HandlerConfig :: Config
	local particle = assets.Particle:Clone()
	particle.Position = hit.HitPos
	particle.Parent = MunitionSystemConfig.ProjectileFolder

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
