--!strict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo))

-- FINALS
local speed = 3500

export type Config = {
	CosmeticBullet: BasePart,
}

MunitionController.RayEnded:connect(function(rayHitInfo: RayHitInfo)
	local rayInfo = rayHitInfo.RayInfo
	local handler = rayInfo.MunitionConfig.FXConfig.TrailFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	local config = handler.HandlerConfig :: Config
	local cosmeticBullet = config.CosmeticBullet
	local bullet = cosmeticBullet:Clone()
	bullet.Anchored = true
	bullet.CanCollide = false
	bullet.CanQuery = false
	bullet.CanTouch = false
	bullet.Parent = GunSystemConfig.ProjectileFolder

	local originPos = rayInfo.Origin.Position
	local direction = rayHitInfo.HitPos - originPos
	local distance = direction.Magnitude
	local dirUnit = direction / distance
	bullet.CFrame = CFrame.new(originPos, originPos + dirUnit)

	if distance <= 0.001 then
		Debris:AddItem(bullet, 0.05)
		return
	end

	local traveled = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt: number)
		if traveled == 0 then originPos = rayInfo.Origin.Position end

		if bullet.Parent and traveled < distance then
			local pos = originPos + dirUnit * traveled
			bullet.CFrame = CFrame.new(pos, pos + dirUnit)
			traveled += speed * dt
		else
			bullet.CFrame = CFrame.new(rayHitInfo.HitPos, rayHitInfo.HitPos + dirUnit)
			connection:Disconnect()
			Debris:AddItem(bullet, 0.05)
		end
	end)
end)

return module
