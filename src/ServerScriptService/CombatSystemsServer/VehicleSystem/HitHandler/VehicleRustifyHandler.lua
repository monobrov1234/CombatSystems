--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local MunitionRayHitInfo = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.SharedEntities.RayInfo.MunitionRayHitInfo)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local DObjectHitService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.DObjectService.DObjectHitService)

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleRustifyHandler")

local STEP_PERCENT = 20
local RUST_ATTRIBUTE = "Rusty"
local RUST_COLOR = Color3.fromRGB(0, 0, 0)
local RUST_MATERIAL = Enum.Material.CorrodedMetal

type CacheData = {
	Parts: { BasePart }, -- all vehicle parts
	PrevHealth: number, -- vehicle health on last rust render
}
local cacheMap = {} :: { [Model]: CacheData }

function funcs.handleHit(ray: RayTypeService.RayInfo, rayHit: MunitionRayHitInfo.Common, objectHit: DObjectHitService.ObjectHitInfo)
	if objectHit.Damage == 0 then return end

	-- verify that this object is a vehicle
	local vehicle = objectHit.Object.object :: Instance
	if not vehicle:IsA("Model") then return end
	if not VehicleUtil.validateVehicle(vehicle) then return end

	local currentTime = os.clock()

	local cacheData: CacheData? = cacheMap[vehicle]
	if not cacheData then
		-- cache the vehicle
		cacheData = {
			Parts = funcs.getVehicleParts(vehicle),
			PrevHealth = objectHit.Object:getMaxHealth(),
		}
		cacheMap[vehicle] = cacheData

		-- remove from the cache when vehicle will be destroyed
		vehicle.AncestryChanged:Connect(function(oldParent: Instance, newParent: Instance?)
			if not newParent then
				cacheMap[vehicle] = nil
				log:debug("Removed vehicle from rust cache: {}", vehicle.Name)
			end
		end)

		log:debug("Cached vehicle in rust cache: {}", vehicle.Name)
	end

	assert(cacheData)

	-- calculate the health lost percent
	local maxHealth = objectHit.Object:getMaxHealth()
	local lostHealthPercent = funcs.getLostHealthPercent(objectHit.Object:getHealth(), maxHealth)
	local prevHealthPercent = funcs.getLostHealthPercent(cacheData.PrevHealth, maxHealth)

	-- do not render rust if the lost health percent isn't enough
	if lostHealthPercent - prevHealthPercent >= STEP_PERCENT then
		cacheData.PrevHealth = objectHit.Object:getHealth()

		-- get the parts that should be rusted (excluding already rusted)
		local rustedParts: { BasePart } = funcs.getRustedPartsPercent(lostHealthPercent, cacheData.Parts)

		-- rustify those parts
		for _, part: BasePart in ipairs(rustedParts) do
			funcs.rustifyPart(part)
		end

		log:debug("Time taken rustifying: {:.1f}ms", (os.clock() - currentTime) * 1000)
	end
end

function funcs.getLostHealthPercent(health: number, maxHealth: number): number
	local lost = (maxHealth - health) / maxHealth
	return math.clamp(lost * 100, 0, 100)
end

function funcs.rustifyPart(part: BasePart)
	part.Color = RUST_COLOR
	part.Material = RUST_MATERIAL
	part:SetAttribute(RUST_ATTRIBUTE, true)
end

function funcs.getRustedPartsPercent(percent: number, parts: { BasePart }): { BasePart }
	-- Clamp input to avoid invalid values
	percent = math.clamp(percent, 0, 100)

	local totalParts = #parts
	if totalParts == 0 then return {} end

	-- How many parts should be rusted in total for this percent
	local targetRustedCount = math.floor(totalParts * (percent / 100) + 0.00001)

	-- Count currently rusted and gather candidates (not rusted yet)
	local currentRustedCount = 0
	local candidates: { BasePart } = {}
	for _, part in ipairs(parts) do
		-- If parts list is cached, some parts can be removed/destroyed; skip invalid ones
		if not part.Parent then continue end
		if funcs.isRustedPart(part) then
			currentRustedCount += 1
		else
			candidates[#candidates + 1] = part
		end
	end

	local needed = targetRustedCount - currentRustedCount
	if needed <= 0 then return {} end

	needed = math.min(needed, #candidates)
	if needed <= 0 then return {} end

	-- Pick `needed` random candidates (without repeats)
	local selected: { BasePart } = {}
	for i = 1, needed do
		local idx = math.random(1, #candidates)
		selected[#selected + 1] = candidates[idx]
		table.remove(candidates, idx)
	end

	return selected
end

function funcs.isRustedPart(part: BasePart): boolean
	return part:GetAttribute(RUST_ATTRIBUTE) ~= nil
end

function funcs.getVehicleParts(vehicle: Model): { BasePart }
	local parts = {} :: { BasePart }
	for _, part: Instance in vehicle:GetDescendants() do
		if part:IsA("BasePart") then table.insert(parts, part :: BasePart) end
	end

	return parts
end

DObjectHitService.ObjectHit:connect(funcs.handleHit)

return module
