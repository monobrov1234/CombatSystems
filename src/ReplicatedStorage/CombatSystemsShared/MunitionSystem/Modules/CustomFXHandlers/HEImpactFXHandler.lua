--!strict

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

type HandlerConfig = {
	ExplosionType: "Small" | "Normal",
}

MunitionController.RayEnded:connect(function(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common)
	local handler = ray.MunitionConfig.FXConfig.ImpactFXHandler
	if not handler or handler.HandlerModuleName ~= "HEImpactFXHandler" then return end
	if not hit.Hit then return end

	local config = handler.HandlerConfig :: HandlerConfig
	local explosion: BasePart
	if config.ExplosionType == "Small" then
		explosion = script.SmallExplosion:Clone()
	elseif config.ExplosionType == "Normal" then
		explosion = script.Explosion:Clone()
	end

	assert(explosion, "Invalid explosion type " .. tostring(config.ExplosionType))

	explosion.Position = hit.HitPos
	explosion.Parent = MunitionSystemConfig.ProjectileFolder
	local sound = explosion:FindFirstChildOfClass("Sound")
	if sound then sound:Play() end

	for i, v in pairs(explosion:GetChildren()) do
		if not v:IsA("ParticleEmitter") then continue end

		local emitSize: Instance? = v:FindFirstChild("EmitSize")
		if emitSize and emitSize:IsA("NumberValue") then
			v:Emit(emitSize.Value)
		else
			v:Emit()
		end
	end

	task.delay(10, function()
		if explosion then explosion:Destroy() end
	end)
end)

return module
