--!strict

local module = {}

-- IMPORTS
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraShaker = require(ReplicatedStorage.CombatSystemsShared.Libs.CameraShaker)
local CameraShakeInstance = require(ReplicatedStorage.CombatSystemsShared.Libs.CameraShaker.CameraShakeInstance)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer :: Player
local playerGui = player.PlayerGui
local character = player.Character or player.CharacterAdded:Wait()
local suppressionHud = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("GunSystemGui"):WaitForChild("SuppressionHud")

local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf: CFrame)
	local camera = workspace.CurrentCamera
	if camera then camera.CFrame = camera.CFrame * shakeCf end
end)
camShake:Start()

local tween = function(
	object: Instance,
	propertyTable: { [string]: any },
	tweenTime: number,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection
)
	return game:GetService("TweenService"):Create(object, TweenInfo.new(tweenTime, easingStyle, easingDirection, 0, false, 0), propertyTable)
end

export type ShakeConfig = {
	MagnitudeMult: number,
	Roughness: number,
	FadeInTime: number,
	FadeOutTime: number,
	PosInfluence: Vector3,
	RotInfluence: Vector3,
}

function module.drawTense(distance: number, maxDistance: number, tenseStay: number, transparencyMultiplier: number, timeMultiplier: number)
	if distance > maxDistance then return end
	local linear = 1 - distance / maxDistance
	local interpolation = linear ^ 2
	local vign: ImageLabel = suppressionHud.Tense.TenseImage:Clone()
	vign.Parent = suppressionHud.Tense
	vign.ImageTransparency = (1 - linear / 1.5) * transparencyMultiplier
	task.delay(tenseStay, function()
		local tw = tween(vign, { ImageTransparency = 1 }, interpolation * timeMultiplier, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		tw.Completed:Connect(function()
			vign:Destroy()
		end)
		tw:Play()
	end)
end

function module.shakeCamera(distance: number, maxDistance: number, shakeConfig: ShakeConfig)
	if distance > maxDistance then return end
	local linear = 1 - distance / maxDistance
	local interpolation = linear ^ 2
	local c = CameraShakeInstance.new(
		interpolation * shakeConfig.MagnitudeMult,
		shakeConfig.Roughness,
		shakeConfig.FadeInTime,
		shakeConfig.FadeOutTime * (1 + interpolation)
	)
	c.PositionInfluence = shakeConfig.PosInfluence
	c.RotationInfluence = shakeConfig.RotInfluence
	camShake:Shake(c)
end

player.CharacterAdded:Connect(function(newCharacter: Model)
	character = newCharacter
	suppressionHud = playerGui:WaitForChild("CombatSystemsGui").GunSystemGui.SuppressionHud
end)

return module
