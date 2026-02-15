local module = {}

function module:CalculateAngleToHit(origin: Vector3, target: Vector3, velocity: number)
	local difference = target - origin
	local horizontalDistance = Vector2.new(difference.X, difference.Z).Magnitude
	local verticalDistance = difference.Y

	local g = workspace.Gravity

	local inRoot = velocity ^ 4 - g * (g * horizontalDistance ^ 2 + 2 * verticalDistance * velocity ^ 2)

	if inRoot < 0 then
		return nil -- Unable to hit the target
	end

	local root = math.sqrt(inRoot)

	local angle1 = math.atan((velocity ^ 2 + root) / (g * horizontalDistance))
	local angle2 = math.atan((velocity ^ 2 - root) / (g * horizontalDistance))

	local answer1 = math.deg(angle1)
	local answer2 = math.deg(angle2)

	warn(answer1, answer2)

	if answer1 < answer2 then
		return answer1
	else
		return answer2
	end
end

function module:ComputeProjectileRaycastHit(origin: Vector3, v: Vector3, a: Vector3, r: number, s: number, raypar: RaycastParams)
	assert(origin, "Origin cannot be nil")
	assert(v, "Velocity cannot be nil")
	assert(a, "Acceleration cannot be nil")
	assert(r, "Resolution cannot be nil")
	assert(s, "Steps cannot be nil")
	assert(s >= 1, "s: Steps must be equal or more than 1")

	-- Resolution is inversely proportional
	r = 1 / r

	local result
	local pVprev = origin
	local pVcurr = origin

	for i = 1, math.ceil(s / r) do
		pVcurr += (v * r)
		v += (a * r)

		-- Raycast check
		local segmentDisplacement = pVcurr - pVprev
		result = workspace:Raycast(pVprev, segmentDisplacement, raypar)

		if result then break end

		pVprev = pVcurr
	end

	return result
end

return module
