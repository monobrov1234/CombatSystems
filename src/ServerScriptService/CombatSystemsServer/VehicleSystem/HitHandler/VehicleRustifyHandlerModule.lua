--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local DestructibleObject = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DestructibleObjectModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)
local DestructibleObjectService = require(ServerScriptService.CombatSystemsServer.GunSystem.DestructibleObjectService.DestructibleObjectServiceModule)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.RayTypeServiceModule)

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleDestroyHandler")

local STEP_PERCENT = 20
local RUST_ATTRIBUTE = "Rusty"
local RUST_COLOR = Color3.fromRGB(0, 0, 0)
local RUST_MATERIAL = Enum.Material.CorrodedMetal

type CacheData = {
	Parts: { BasePart }, -- all vehicle parts
	PrevHealth: number, -- vehicle health on last rust render
}
local cacheMap = {} :: { [Model]: CacheData }

function funcs.handleHit(object: DestructibleObject.SelfObject, foundArmorInfo: DestructibleObjectUtil.ArmorInfo, damage: number, rayHitInfo: RayTypeService.RayHitInfo)
	if damage == 0 then return end

	-- verify that this object is a vehicle
	local vehicle = object.object :: Instance
	if not vehicle:IsA("Model") then return end
	if not VehicleUtil.validateVehicle(vehicle) then return end

	local currentTime = os.clock()
	debug.profilebegin("rustVehicle")

	local cacheData: CacheData? = cacheMap[vehicle]
	if not cacheData then
		-- cache the vehicle
		cacheData = {
			Parts = funcs.getVehicleParts(vehicle),
			PrevHealth = object:getMaxHealth(),
		}
		cacheMap[vehicle] = cacheData

		-- remove from cache when it's destroyed
		vehicle.Destroying:Connect(function()
			log:trace("Removed vehicle from rust cache: {}", vehicle.Name)
			cacheMap[vehicle] = nil
		end)

		log:trace("Cached vehicle in rust cache: {}", vehicle.Name)
	end

	local cacheData = cacheData :: CacheData

	-- calculate health lost percent
	local maxHealth = object:getMaxHealth()
	local lostHealthPercent = funcs.getLostHealthPercent(object:getHealth(), maxHealth)
	local prevHealthPercent = funcs.getLostHealthPercent(cacheData.PrevHealth, maxHealth)

	-- do not render rust if lost health percent isn't enough
	if lostHealthPercent - prevHealthPercent >= STEP_PERCENT then
		cacheData.PrevHealth = object:getHealth()

		-- get the parts that should be rusted (excluding already rusted)
		local rustedParts: { BasePart } = funcs.getRustedPartsPercent(lostHealthPercent, cacheData.Parts)

		-- rustify those parts
		for _, part: BasePart in ipairs(rustedParts) do
			funcs.rustifyPart(part)
		end

		log:trace("Time taken rustifying: {:.1f}ms", (os.clock() - currentTime) * 1000)
	end

	debug.profileend()
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

DestructibleObjectService.ObjectHit:connect(funcs.handleHit)

return module
