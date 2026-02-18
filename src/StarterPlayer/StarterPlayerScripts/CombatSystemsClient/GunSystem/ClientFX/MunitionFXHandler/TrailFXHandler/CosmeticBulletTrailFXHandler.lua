--!strict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)

-- FINALS
local cosmeticBulletsCache = {} :: { [string]: BasePart }

export type Config = {
	CosmeticBullet: BasePart,
}

MunitionController.RayFired:connect(function(rayInfo: MunitionController.RayInfo)
	local handler = rayInfo.MunitionConfig.FXConfig.TrailFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end
	local config = handler.HandlerConfig :: Config
	assert(config.CosmeticBullet)

	local cosmeticBulletClone = config.CosmeticBullet:Clone()
	cosmeticBulletClone.Parent = GunSystemConfig.ProjectileFolder
	cosmeticBulletsCache[rayInfo.RayId] = cosmeticBulletClone
end)

MunitionController.RaySegmentReached:connect(function(rayInfo: MunitionController.RayInfo, segmentOrigin: Vector3, direction: Vector3, length: number)
	local handler = rayInfo.MunitionConfig.FXConfig.TrailFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	local cosmeticBullet = cosmeticBulletsCache[rayInfo.RayId]
	local bulletLength = cosmeticBullet.Size.Z / 2
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + direction)
	cosmeticBullet.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
end)

MunitionController.RayEnded:connect(function(rayHitInfo: MunitionController.RayHitInfo)
	local rayInfo = rayHitInfo.RayInfo
	local handler = rayInfo.MunitionConfig.FXConfig.TrailFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	-- recheck memory leaks
	cosmeticBulletsCache[rayInfo.RayId]:Destroy()
	cosmeticBulletsCache[rayInfo.RayId] = nil
end)

return module
