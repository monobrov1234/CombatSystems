--!strict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo))

-- FINALS
local muzzleFlashRays = {} :: { [BasePart]: boolean }

MunitionController.RayFired:connect(function(rayInfo: RayInfo)
	local origin = rayInfo.Origin
	print(origin.Name)
	local handler = rayInfo.MunitionConfig.FXConfig.ShootFXHandler
	if not handler or handler.HandlerModuleName ~= script.Name then return end

	for i, v: Instance in pairs(origin:GetDescendants()) do
		if not v:IsA("ParticleEmitter") then continue end

		local amount = 1
		if v:FindFirstChild("Amount") then
			amount = v.Amount.Value
		elseif v:FindFirstChild("EmitSize") then
			amount = v.EmitSize.Value
		end

		v:Emit(amount)
	end

	if muzzleFlashRays[origin] then return end
	muzzleFlashRays[origin] = true

	local light = origin:FindFirstChild("Light") :: Light?
	if light then
		light.Enabled = true
		task.delay(0.1, function()
			if light then light.Enabled = false end
			muzzleFlashRays[origin] = nil
		end)
	end
end)

return module
