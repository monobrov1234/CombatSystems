local module = {}

-- This function calculates the shortest distance from a point in the world (worldPoint) to the closest point on (or inside) the part’s oriented bounding box.
function module.distanceToPartBounds(worldPoint: Vector3, part: BasePart): number
	local localPoint = part.CFrame:PointToObjectSpace(worldPoint)
	local half = part.Size * 0.5
	local clamped = Vector3.new(math.clamp(localPoint.X, -half.X, half.X), math.clamp(localPoint.Y, -half.Y, half.Y), math.clamp(localPoint.Z, -half.Z, half.Z))
	return (localPoint - clamped).Magnitude
end

return module
