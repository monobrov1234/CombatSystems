--!strict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionControllerModule)

-- FINALS
local muzzleFlashRays = {} :: { [BasePart]: boolean }

MunitionController.RayFired:connect(function(ray: MunitionController.RayInfo)
	if not ray.Origin then return end
	
	local origin = ray.Origin
	local handler = ray.MunitionConfig.FXConfig.ShootFXHandler
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
