--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.MunitionConfigUtilModule)

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
	Origin: BasePart,
	InitOriginPos: Vector3,
	InitDirection: Vector3,
	RaycastParams: RaycastParams?
}

export type RaySegmentInfo = {
	RayInfo: RayInfo,
	OriginPos: Vector3,
	DirectionVec: Vector3,
	Length: number
}

export type RayHitInfo = {
	RayInfo: RayInfo,
	HitPos: Vector3,
	Hit: BasePart?
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

	local rayInfo: RayInfo = {
		Player = player,
		Team = player.Team,
		RayId = HttpService:GenerateGUID(),
		MunitionConfig = config,
		Origin = info.Origin,
		InitOriginPos = info.Origin.Position,
		InitDirection = info.DirectionVec,
		RaycastParams = info.RaycastParams,
	}
	module.PreFire:fire(rayInfo)
end

function module.processFireMunition(rayInfo: RayInfo) 
	module.RayFired:fire(rayInfo)
end

function module.processRaySegment(segmentInfo: RaySegmentInfo) 
	module.RaySegmentReached:fire(segmentInfo)
end

function module.processRayEnd(rayHitInfo: RayHitInfo)
	module.RayEnded:fire(rayHitInfo)
end

return module
