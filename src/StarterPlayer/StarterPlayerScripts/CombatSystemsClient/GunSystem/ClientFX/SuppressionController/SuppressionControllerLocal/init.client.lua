--!strict

local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local PlayerScripts = (Players.LocalPlayer :: Player).PlayerScripts :: typeof(game.StarterPlayer.StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)
local MunitionController = require(PlayerScripts.CombatSystemsClient.GunSystem.MunitionController.MunitionControllerModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))
type RayHitInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo))

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

function funcs.handleRaySegmentReached(segment: MunitionController.RaySegmentInfo)
	local rayInfo = segment.RayInfo
	if rayInfo.Player == player then return end
	if not rayInfo.MunitionConfig.CanSuppress then return end

	local distance = funcs.distanceFromRay(rootPart.Position, rayInfo.InitOriginPos, rayInfo.InitDirection, segment.Length)
	funcs.suppress(rayInfo.Team, rayInfo.MunitionConfig, distance, true)
end

function funcs.handleRayEnded(rayHitInfo: MunitionController.RayHitInfo) 
	local rayInfo = rayHitInfo.RayInfo
	if rayInfo.Player == player then return end
	if not rayInfo.MunitionConfig.CanSuppressImpact then return end

	if rayHitInfo.Hit then
		local distance = (rootPart.Position - rayHitInfo.HitPos).Magnitude
		funcs.suppress(rayInfo.Team, rayInfo.MunitionConfig, distance, false)
	end

	-- recheck memory leaks
	-- clean up
	local rayIdIndex = table.find(rayIdMap, rayInfo.RayId)
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

function funcs.distanceFromRay(targetPos: Vector3, originPos: Vector3, direction: Vector3, length: number): number
	if direction.Magnitude == 0 then return math.huge end

	local dir: Vector3 = direction.Unit
	local rayEnd: Vector3 = originPos + dir * length
	local AP: Vector3 = targetPos - originPos
	local AB: Vector3 = rayEnd - originPos
	local abLengthSquared: number = AB:Dot(AB)
	if abLengthSquared == 0 then return (targetPos - originPos).Magnitude end

	local t: number = AP:Dot(AB) / abLengthSquared
	t = math.clamp(t, 0, 1)

	local closestPoint: Vector3 = originPos + AB * t
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