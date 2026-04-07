--!strict
-- TODO: rework this handler, mainly move everything into configs

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.DestructibleObjectConfig)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local DObjectHitService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.DObjectService.DObjectHitService)

-- ROBLOX OBJECTS
local assets = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Assets.VehicleWreckDestroyHandler

-- FINALS
local _log: Logger.SelfObject = Logger.new("VehicleWreckDestroyHandler")

local RUST_COLOR = Color3.fromRGB(0, 0, 0)
local RUST_MATERIAL = Enum.Material.CorrodedMetal

-- INTERNAL FUNCTIONS
function funcs.handleHit(ray: RayTypeService.RayInfo, rayHit: MunitionRayHitInfo.Common, objectHit: DObjectHitService.ObjectHitInfo): boolean
	if objectHit.Damage == 0 then return false end
	if objectHit.Object:getHealth() > 0 then return false end

	local vehicle = objectHit.Object.object :: Instance
	if not vehicle:IsA("Model") then return false end
	if not VehicleUtil.validateVehicle(vehicle) then return false end

	local vehicleInfo = VehicleUtil.parseVehicleInfo(vehicle)

	vehicle:RemoveTag(VehicleSystemConfig.Tag)
	vehicle:RemoveTag(DestructibleObjectConfig.Tag)

	for _, part: Instance in ipairs(vehicle:GetDescendants() :: { Instance }) do
		if part:IsA("BasePart") then
			part.Color = RUST_COLOR
			part.Material = RUST_MATERIAL
		elseif part:IsA("ProximityPrompt") then
			part:Destroy()
		elseif part:IsA("CylindricalConstraint") then
			part.AngularActuatorType = Enum.ActuatorType.None
		end
	end

	task.delay(10, function()
		vehicle:Destroy()
	end)

	local sound: Sound = assets.PipeSound:Clone()
	sound.Parent = vehicle.PrimaryPart
	sound:Play()

	local sound2: Sound = assets.ExplosionSound:Clone()
	sound2.Parent = vehicle.PrimaryPart
	sound2:Play()

	local engineFire = vehicleInfo.SystemParts:FindFirstChild("EngineFire") :: BasePart?
	if engineFire then
		local burning = engineFire:FindFirstChild("Burning") :: Sound
		burning:Play()

		local burningLight = engineFire:FindFirstChild("BurningLight") :: Light
		burningLight.Enabled = true

		for _, emitter: Instance in ipairs(engineFire:GetDescendants() :: { Instance }) do
			if emitter:IsA("ParticleEmitter") then emitter.Enabled = true end
		end
	end

	return true
end

-- SUBSCRIPTIONS
DObjectHitService.ObjectHit:connect(funcs.handleHit, Signal.Priority.NORMAL - 5)

return module
