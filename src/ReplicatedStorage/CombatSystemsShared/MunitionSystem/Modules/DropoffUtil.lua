--!strict

local module = {}

function module.calculateExplosionDropoff(damage: number, distance: number, dropoffStartRadius: number, radius: number): number
	-- check that the hit is within the radius
	if distance > radius then return 0 end
	-- check that the hit is within the dropoff start radius, return damage if it is
	if distance <= dropoffStartRadius then return damage end
	local realDistance = distance - dropoffStartRadius
	local maxDistance = radius - dropoffStartRadius
	return module.calculateDropoff(damage, realDistance, 0, maxDistance)
end

function module.calculateDropoff(damage: number, distance: number, dropoffDistance: number, maxDistance: number): number
	if distance >= maxDistance then return 0 end
	if distance <= dropoffDistance then return damage end
	local falloff = 1 - ((distance - dropoffDistance) / (maxDistance - dropoffDistance))
	return damage * math.clamp(falloff, 0, 1)
end

return module
