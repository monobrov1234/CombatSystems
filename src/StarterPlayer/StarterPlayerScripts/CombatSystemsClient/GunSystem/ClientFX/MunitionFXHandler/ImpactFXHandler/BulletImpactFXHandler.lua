--!nonstrict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)

-- FINALS
export type Config = {
	Color: ColorSequence,
}

MunitionController.RayEnded:connect(function(rayHitInfo: MunitionController.RayHitInfo)
	local rayInfo = rayHitInfo.RayInfo
	local handler = rayInfo.MunitionConfig.FXConfig.ImpactFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	-- this is from trek
	local config = handler.HandlerConfig :: Config
	local particle = script.Particle:Clone()
	particle.Position = rayHitInfo.HitPos
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
