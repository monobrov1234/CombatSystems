--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local MunitionRayInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer :: Player

-- FINALS
local _log: Logger.SelfObject = Logger.new("MunitionController")

export type FireMunitionInfo = {
	MunitionName: string,
	Origin: BasePart,
	DirectionVec: Vector3,
	RaycastParams: RaycastParams?,
	SpreadYawDeg: number,
	SpreadPitchDeg: number
}

export type RayInfo = {
	Player: Player?,
	Team: Team?,
	RayId: string,
	MunitionConfig: MunitionConfigUtil.DefaultType,
	Origin: BasePart?,
	Body: MunitionRayInfo.Common,
	RaycastParams: RaycastParams?
}

export type RaySegmentInfo = {
	OriginPos: Vector3,
	DirectionVec: Vector3,
	Length: number
}

-- PUBLIC EVENTS
module.PreFire = Signal.new()
module.RayFired = Signal.new()
module.RaySegmentReached = Signal.new()
module.RayEnded = Signal.new()

-- PUBLIC API
function module.fireMunition(info: FireMunitionInfo)
	local config = MunitionConfigUtil.getConfig(info.MunitionName)
	assert(config, "Munition " .. info.MunitionName .. " doesn't have config")

	-- spread calculation, client side
	if info.SpreadYawDeg > 0 or info.SpreadPitchDeg > 0 then
		local yaw = (math.random() - 0.5) * 2 * math.rad(info.SpreadYawDeg)
		local pitch = (math.random() - 0.5) * 2 * math.rad(info.SpreadPitchDeg)
		local originPos = info.Origin.Position
		local cf = CFrame.lookAt(originPos, originPos + info.DirectionVec)
		cf = cf * CFrame.Angles(0, yaw, 0)
		cf = cf * CFrame.Angles(pitch, 0, 0)
		info.DirectionVec = cf.LookVector
	end

	local ray: RayInfo = {
		Player = player,
		Team = player.Team,
		RayId = HttpService:GenerateGUID(),
		MunitionConfig = config,
		Origin = info.Origin,
		Body = {
			InitOriginPos = info.Origin.Position,
			InitDirection = info.DirectionVec,
		},
		RaycastParams = info.RaycastParams,
	}
	module.PreFire:fire(ray)
end

function module.processFireMunition(ray: RayInfo) 
	module.RayFired:fire(ray)
end

function module.processRaySegment(ray: RayInfo, segment: RaySegmentInfo) 
	module.RaySegmentReached:fire(ray, segment)
end

function module.processRayEnd(ray: RayInfo, hit: MunitionRayHitInfo.Common)
	module.RayEnded:fire(ray, hit)
end

return module
