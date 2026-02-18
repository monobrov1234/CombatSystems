--!strict
-- TODO: rework this handler, mainly move everything into configs

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSystemConfig)
local DestructibleObjectService = require(ServerScriptService.CombatSystemsServer.GunSystem.DestructibleObjectService.DestructibleObjectServiceModule)
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.DestructibleObjectConfig)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.RayTypeServiceModule)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)

-- FINALS
local _log: Logger.SelfObject = Logger.new("VehicleDestroyHandler")

local RUST_COLOR = Color3.fromRGB(0, 0, 0)
local RUST_MATERIAL = Enum.Material.CorrodedMetal

function funcs.handleHit(ray: RayTypeService.RayInfo, rayHit: MunitionRayHitInfo.Common, objectHit: DestructibleObjectService.ObjectHitInfo): boolean
	if objectHit.Damage == 0 then return false end
	if objectHit.Object:getHealth() > 0 then return false end

	-- verify that this object is a vehicle
	local vehicle = objectHit.Object.object :: Instance
	if not vehicle:IsA("Model") then return false end
	if not VehicleUtil.validateVehicle(vehicle) then return false end

	local vehicleInfo = VehicleUtil.parseVehicleInfo(vehicle)

	-- remove the destructible object marker and vehicle tag so the vehicle will be treated as a normal part
	vehicle:RemoveTag(VehicleSystemConfig.Tag)
	vehicle:RemoveTag(DestructibleObjectConfig.Tag)

	-- transform the vehicle into a wreck
	for _, part: Instance in ipairs(vehicle:GetDescendants() :: { Instance }) do
		if part:IsA("BasePart") then
			part.Color = RUST_COLOR
			part.Material = RUST_MATERIAL
		elseif part:IsA("ProximityPrompt") then
			part:Destroy() -- remove all the seat prompts
		elseif part:IsA("CylindricalConstraint") then
			part.AngularActuatorType = Enum.ActuatorType.None -- disable the wheel motor
		end
	end

	-- remove the wreck after 10 seconds
	task.delay(10, function()
		vehicle:Destroy()
	end)

	-- play the destroy sound
	local sound: Sound = script.PipeSound:Clone()
	sound.Parent = vehicle.PrimaryPart
	sound:Play()

	local sound2: Sound = script.ExplosionSound:Clone()
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

	-- cancel the event by returning true
	return true
end

DestructibleObjectService.ObjectHit:connect(funcs.handleHit, Signal.Priority.NORMAL - 5) -- execute before the default handler (LOW priority) so we can properly cancel the event

return module
