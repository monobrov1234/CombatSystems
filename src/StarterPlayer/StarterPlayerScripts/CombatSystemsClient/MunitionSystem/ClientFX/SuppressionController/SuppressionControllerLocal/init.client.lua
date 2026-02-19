--!strict

local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)
local MunitionController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.MunitionControllerModule)

-- IMPORTS INTERNAL
local SuppressUtil = require(script.SuppressUtilModule)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer :: Player
local character: Model = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

-- FINALS
local MAX_DISTANCE = 24
local rayIdMap = {} :: { string }

function funcs.handleRaySegmentReached(ray: MunitionController.RayInfo, segment: MunitionController.RaySegmentInfo)
	if ray.Player == player then return end
	if not ray.MunitionConfig.CanSuppress then return end

	local distance = funcs.distanceFromRay(rootPart.Position, ray.Body, segment)
	funcs.suppress(ray.Team, ray.MunitionConfig, distance, true)
end

function funcs.handleRayEnded(ray: MunitionController.RayInfo, hit: MunitionRayHitInfo.Common) 
	if ray.Player == player then return end
	if not ray.MunitionConfig.CanSuppressImpact then return end

	if hit.Hit then
		local distance = (rootPart.Position - hit.HitPos).Magnitude
		funcs.suppress(ray.Team, ray.MunitionConfig, distance, false)
	end

	-- recheck memory leaks
	-- clean up
	local rayIdIndex = table.find(rayIdMap, ray.RayId)
	if rayIdIndex then table.remove(rayIdMap, rayIdIndex) end
end

function funcs.suppress(shooterTeam: Team?, munitionConfig: MunitionConfigUtil.DefaultType, distance: number, trailEvent: boolean)
	if shooterTeam and shooterTeam == player.Team then return end -- TEAMMATE CHECK
	if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then return end
	if distance > MAX_DISTANCE then return end

	local suppressionConfig = munitionConfig.SuppressionConfig
	if suppressionConfig.EnableTense then
		local tenseConfig = suppressionConfig.TenseConfig
		SuppressUtil.drawTense(distance, MAX_DISTANCE, tenseConfig.StayTime, tenseConfig.TransparencyMultiplier, tenseConfig.FadeOutTimeMultiplier)
	end

	if suppressionConfig.EnableCameraShake then
		local shakeConfig: SuppressUtil.ShakeConfig?
		if trailEvent then
			shakeConfig = suppressionConfig.TrailCameraShakeConfig :: SuppressUtil.ShakeConfig?
		else
			shakeConfig = suppressionConfig.ImpactCameraShakeConfig :: SuppressUtil.ShakeConfig?
		end

		if shakeConfig then SuppressUtil.shakeCamera(distance, MAX_DISTANCE, shakeConfig :: SuppressUtil.ShakeConfig) end
	end
end

function funcs.distanceFromRay(targetPos: Vector3, ray: MunitionRayInfo.Common, segment: MunitionController.RaySegmentInfo): number
	if ray.InitDirection.Magnitude == 0 then return math.huge end

	local dir: Vector3 = ray.InitDirection.Unit
	local rayEnd: Vector3 = ray.InitOriginPos + dir * segment.Length
	local AP: Vector3 = targetPos - ray.InitOriginPos
	local AB: Vector3 = rayEnd - ray.InitOriginPos
	local abLengthSquared: number = AB:Dot(AB)
	if abLengthSquared == 0 then return (targetPos - ray.InitOriginPos).Magnitude end

	local t: number = AP:Dot(AB) / abLengthSquared
	t = math.clamp(t, 0, 1)

	local closestPoint: Vector3 = ray.InitOriginPos + AB * t
	local distance: number = (targetPos - closestPoint).Magnitude
	return distance
end

player.CharacterAdded:Connect(function(newCharacter: Model)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
end)

MunitionController.RaySegmentReached:connect(funcs.handleRaySegmentReached)
MunitionController.RayEnded:connect(funcs.handleRayEnded)