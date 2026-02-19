-- made by chatgpt 5.2
--!strict

local CameraRecoil = {}
local funcs = {}
CameraRecoil.__index = CameraRecoil

-- IMPORTS
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

type KickJob = {
	delta: Vector3, -- total radians to apply
	elapsed: number, -- seconds passed since kick start
	duration: number, -- seconds to apply full delta
	lastAlpha: number, -- previous interpolation value
}

export type SelfObject = typeof(setmetatable({}, CameraRecoil)) & {
	-- FINALS
	bindName: string,
	-- STATE
	offset: Vector3, -- accumulated recoil (radians)
	applied: Vector3, -- last applied recoil (radians)
	kicks: { KickJob },
	running: boolean,
}
function CameraRecoil.new(): SelfObject
	local self = setmetatable({}, CameraRecoil) :: SelfObject
	self.bindName = "CameraRecoil_" .. HttpService:GenerateGUID(false)
	self.running = false
	self.offset = Vector3.new()
	self.applied = Vector3.new()
	self.kicks = {}
	return self
end

function funcs.easeOutCubic(u: number): number
	local x = math.clamp(u, 0, 1)
	local inv = 1 - x
	return 1 - inv * inv * inv
end

-- Rotate around a world-space axis without rebuilding orientation
local function rotateAround(cf: CFrame, axis: Vector3, angle: number): CFrame
	if angle == 0 then return cf end

	local pos = cf.Position
	return CFrame.new(pos) * CFrame.fromAxisAngle(axis.Unit, angle) * CFrame.new(-pos) * cf
end

-- pitchDeg = X, yawDeg = Y, rollDeg = Z (degrees)
-- lerpTime = seconds to apply full delta (0/nil = instant)
function CameraRecoil:Kick(pitchDeg: number?, yawDeg: number?, rollDeg: number?, strength: number?, lerpTime: number?)
	local self = self :: SelfObject
	strength = strength or 1

	local delta = Vector3.new(math.rad(pitchDeg or 0), math.rad(yawDeg or 0), math.rad(rollDeg or 0)) * strength

	local elapsed = lerpTime or 0
	if elapsed <= 0 then
		self.offset += delta
		return
	end

	table.insert(self.kicks, {
		delta = delta,
		elapsed = 0,
		duration = elapsed,
		lastAlpha = 0,
	})
end

function CameraRecoil:_step(dt: number)
	local self = self :: SelfObject
	local camera = workspace.CurrentCamera
	if not camera then return end

	-- Clamp dt to avoid recoil loss on lag spikes
	if dt > (1 / 20) then dt = 1 / 20 end

	-- Apply lerped kick jobs (guaranteed full delta)
	for i = #self.kicks, 1, -1 do
		local k = self.kicks[i]
		k.elapsed += dt

		local a = funcs.easeOutCubic(k.elapsed / k.duration)
		local da = a - k.lastAlpha
		k.lastAlpha = a

		self.offset += k.delta * da

		if k.elapsed >= k.duration then table.remove(self.kicks, i) end
	end

	-- Apply only the delta since last frame
	local d = self.offset - self.applied
	if d.Magnitude == 0 then return end
	self.applied = self.offset

	local cf = camera.CFrame

	-- Yaw around WORLD Y
	cf = rotateAround(cf, Vector3.yAxis, d.Y)

	-- Pitch around camera RightVector
	cf = rotateAround(cf, cf.RightVector, d.X)

	-- Roll only if explicitly used
	if d.Z ~= 0 then cf = rotateAround(cf, cf.LookVector, d.Z) end

	camera.CFrame = cf
end

function CameraRecoil:Start()
	local self = self :: SelfObject
	if self.running then return end
	self.running = true

	RunService:BindToRenderStep(self.bindName, Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:_step(dt)
	end)
end

function CameraRecoil:Stop()
	local self = self :: SelfObject
	if not self.running then return end
	self.running = false
	RunService:UnbindFromRenderStep(self.bindName)
end

function CameraRecoil:Reset()
	local self = self :: SelfObject
	self.offset = Vector3.new()
	self.applied = Vector3.new()
	table.clear(self.kicks)
end

function CameraRecoil:Destroy()
	self:Stop()
end

return CameraRecoil
