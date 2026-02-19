--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local RayTypeService = require(script.Parent.RayTypeService)

-- FINALS
local _log: Logger.SelfObject = Logger.new("MunitionService")

-- validator pipeline, these functions should validate shooting if it is performed from their services weapons
-- if one validator fails, then fire will not be registered
-- validators should throw an exception if they fail
type ValidatorCallback = (rayInfo: RayTypeService.RayInfoNonValid) -> (RaycastParams?)
local validatorPipeline = {} :: { ValidatorCallback }

-- PUBLIC EVENTS

-- called when munition is validated and fully permitted, used by other services for example to update mag size and ammo
module.FireMunition = Signal.new() -- (ray: RayTypeService.RayInfo)
-- called before determining hit type and calculating specifics (e.g explosion hit list)
-- mainly for use in MunitionHitService
module.PreHit = Signal.new() -- (ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.CommonFull)

-- PUBLIC API
function module.validateRayFire(ray: RayTypeService.RayInfoNonValid): RayTypeService.RayInfo
	assert(ray.Player, "Ambiguous validateRay call on a ray without player field")

	local raycastParams: RaycastParams?
	for _, callback: ValidatorCallback in ipairs(validatorPipeline) do
		raycastParams = callback(ray)
		if raycastParams then break end
	end

	-- if every validator not failed but returned nil it probably means that player isn't holding anything but tried to call shooting event
	-- it also could be programmer error if there is no validator registered for their service
	assert(raycastParams, "Player is not using any weapon")

	return RayTypeService.convertNonValidRayInfoToServer(ray, raycastParams)
end

-- WIP function
function module.validateRayHit(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.Common)
	-- TODO: hit validation
end

function module.registerFireValidator(validator: ValidatorCallback)
	table.insert(validatorPipeline, validator)
end

function module.processMunitionFire(ray: RayTypeService.RayInfo)
	module.FireMunition:fire(ray)
end

function module.processMunitionHit(ray: RayTypeService.RayInfo, hit: MunitionRayHitInfo.Common)
	if not hit.Hit then return end
	module.PreHit:fire(ray, hit)
end

return module
