--!strict

local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObjectModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local DObjectDamageService = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedServices.DamageCalculation.DObjectDamageServiceModule)
local HumanoidDamageService = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedServices.DamageCalculation.HumanoidDamageServiceModule)
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)

-- ROBLOX OBJECTS
local playerGui = player.PlayerGui
local mouse = player:GetMouse()
local _character: Model = player.Character or player.CharacterAdded:Wait()
local hitmarkGui = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("GunSystemGui"):WaitForChild("HitmarkGui"):WaitForChild("Hitmark")
local damageContainer = hitmarkGui:WaitForChild("DamageContainer")

local explosionHitmark: RemoteEvent = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.ClientFX.ServerToClient.ExplosionHitmark

-- FINALS
local dObjectTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local humanoidTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local endSize = UDim2.new(0, 60, 0, 20)
local endTransparency = 0.7
local startXMargin = 10
local startYMargin = -10
local endXMargin = 40
local endYMargin = -35
local xMarginRandomness = 10
local yMarginRandomness = 10

local tween = function(object: Instance, goal, tt: number?, es: string, ed: string)
	return TweenService:Create(object, TweenInfo.new(tt, Enum.EasingStyle[es], Enum.EasingDirection[ed], 0, false, 0), goal)
end

function funcs.handleRayEnded(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common)
	if player ~= ray.Player then return end
	if not hit.Hit then return end

	local dObject = DestructibleObject.fromInstanceChild(hit.Hit)
	if dObject and DObjectDamageService.canDamageObject(dObject, ray.MunitionConfig, player.Team) then
		local damage = DObjectDamageService.calculateDirectDamage(ray.MunitionConfig, ray.Body, hit :: MunitionRayHitInfo.CommonFull)
		funcs.showHitmark(damage, Color3.new(0, 0.615686, 1), dObjectTweenInfo)
	else
		local character: Model? = hit.Hit:FindFirstAncestorOfClass("Model")
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		if not HumanoidDamageService.canDamageCharacter(player, player.Team, character, ray.MunitionConfig) then return end

		local expectedDamage = HumanoidDamageService.calculateDirectDamage(ray.Body, hit :: MunitionRayHitInfo.CommonFull, ray.MunitionConfig)
		funcs.showHitmark(expectedDamage, Color3.new(1, 0.235294, 0), humanoidTweenInfo)
	end
end

function funcs.handleExplosionHitmark(totalDamage: number, armored: boolean)
	local color = armored and Color3.fromRGB(21, 0, 255) or Color3.fromRGB(255, 32, 32)
	local box = damageContainer.Box:Clone()
	box.UIStroke.Color = color
	box.Visible = true
	box.Parent = damageContainer

	tween(box, { Size = UDim2.new(0, 80, 0, 80) }, 0.25, "Cubic", "Out"):Play()
	tween(box.UIStroke, { Transparency = 1 }, 0.25, "Linear", "Out"):Play()
	Debris:AddItem(box, 0.5)

	funcs.showHitmark(totalDamage, color, armored and dObjectTweenInfo or humanoidTweenInfo)
end

function funcs.showHitmark(damage: number, color: Color3, tweenInfo: TweenInfo)
	if not hitmarkGui or not hitmarkGui.Parent then return end
	if damage == 0 then return end
	damage = math.round(damage * 100) / 100 -- round to 2 decimal places

	local damageClone = damageContainer.Damage:Clone()
	damageClone.Text.Text = tostring(damage)
	damageClone.Text.TextColor3 = color
	damageClone.Visible = true
	damageClone.Parent = damageContainer

	local randStartX = math.random(-xMarginRandomness, xMarginRandomness)
	local randStartY = math.random(-yMarginRandomness, yMarginRandomness)
	local randEndX = math.random(-xMarginRandomness, xMarginRandomness)
	local randEndY = math.random(-yMarginRandomness, yMarginRandomness)

	local startPos = UDim2.new(0.5, startXMargin + randStartX, 0.5, startYMargin + randStartY)
	damageClone.Position = startPos
	local endPos = UDim2.new(0.5, endXMargin + randEndX, 0.5, endYMargin + randEndY)
	local tween = TweenService:Create(damageClone, tweenInfo, {
		Position = endPos,
	})

	local transparencyTween = TweenService:Create(damageClone.Text, tweenInfo, {
		TextTransparency = endTransparency,
		Size = endSize,
	})

	tween:Play()
	transparencyTween:Play()

	task.delay(tweenInfo.Time, function()
		if damageClone then damageClone:Destroy() end
	end)
end

function funcs.handleMouseMove()
	if not hitmarkGui or not hitmarkGui.Parent then return end
	local inset = GuiService:GetGuiInset()
	damageContainer.Position = UDim2.new(0, mouse.X + inset.X, 0, mouse.Y + inset.Y)
end

mouse.Move:Connect(funcs.handleMouseMove)
MunitionController.RayEnded:connect(funcs.handleRayEnded)
explosionHitmark.OnClientEvent:Connect(funcs.handleExplosionHitmark)

player.CharacterAdded:Connect(function(newCharacter: Model)
	_character = newCharacter
	hitmarkGui = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("GunSystemGui"):WaitForChild("HitmarkGui"):WaitForChild("Hitmark")
	damageContainer = hitmarkGui:WaitForChild("DamageContainer")
end)
