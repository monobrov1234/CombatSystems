--!strict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionSystemConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.MunitionSystemConfig)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionController)

-- FINALS
local cosmeticBulletsCache = {} :: { [string]: BasePart }

export type Config = {
	CosmeticBullet: BasePart,
}

MunitionController.RayFired:connect(function(ray: MunitionController.RayInfo)
	local handler = ray.MunitionConfig.FXConfig.TrailFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end
	local config = handler.HandlerConfig :: Config
	assert(config.CosmeticBullet)

	local cosmeticBulletClone = config.CosmeticBullet:Clone()
	cosmeticBulletClone.Parent = MunitionSystemConfig.ProjectileFolder
	cosmeticBulletsCache[ray.RayId] = cosmeticBulletClone
end)

MunitionController.RaySegmentReached:connect(function(ray: MunitionController.RayInfo, segment: MunitionController.RaySegmentInfo)
	local handler = ray.MunitionConfig.FXConfig.TrailFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	local cosmeticBullet = cosmeticBulletsCache[ray.RayId]
	local bulletLength = cosmeticBullet.Size.Z / 2
	local baseCFrame = CFrame.new(segment.OriginPos, segment.OriginPos + segment.DirectionVec)
	cosmeticBullet.CFrame = baseCFrame * CFrame.new(0, 0, -(segment.Length - bulletLength))
end)

MunitionController.RayEnded:connect(function(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common)
	local handler = ray.MunitionConfig.FXConfig.TrailFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	-- recheck memory leaks
	cosmeticBulletsCache[ray.RayId]:Destroy()
	cosmeticBulletsCache[ray.RayId] = nil
end)

return module
