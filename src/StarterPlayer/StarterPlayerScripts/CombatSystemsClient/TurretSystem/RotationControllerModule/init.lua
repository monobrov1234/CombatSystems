local module = {}
local funcs = {}
module.__index = module

-- IMPORTS
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local TurretConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.TurretConfig)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)

-- IMPORTS INTERNAL
local RotationUtil = require(script.RotationUtilModule)
local TraverseUtil = require(script.TraverseUtilModule)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ReplicateState

-- FINALS
export type SelfObject = typeof(setmetatable({}, module)) & {
	-- FINALS
	turretInfo: TurretUtil.TurretInfo,
	raycastParams: RaycastParams,
	rotationUtil: RotationUtil.SelfObject,
	traverseUtil: TraverseUtil.SelfObject,

	-- STATE
	debugRayPart: Part?,
	lastYawRotation: Vector3,
	lastPitchRotation: Vector3,
	timeAccumulator: number,
}
function module.new(turretInfo: TurretUtil.TurretInfo, raycastParams: RaycastParams, traverseStart: Sound?, traverse: Sound?, traverseEnd: Sound?): SelfObject
	local self = setmetatable({}, module) :: SelfObject

	self.turretInfo = turretInfo
	self.raycastParams = raycastParams
	self.rotationUtil = RotationUtil.new(turretInfo)
	self.traverseUtil = TraverseUtil.new(turretInfo, nil, nil, traverseStart, traverse, traverseEnd)

	self.debugRayPart = nil
	self.lastYawRotation = Vector3.new(math.huge, math.huge, math.huge)
	self.lastPitchRotation = Vector3.new(math.huge, math.huge, math.huge)
	self.timeAccumulator = 0

	return self
end

function module:destroy()
	local self = self :: SelfObject
	if self.debugRayPart then self.debugRayPart:Destroy() end
	self.traverseUtil:destroy()
end

function module:updateTurretRotation(deltaTime: number)
	local self = self :: SelfObject
	if not self.turretInfo.TurretModel.Parent then return end

	-- calculate mouse hit position excluding turret object
	local camera = workspace.CurrentCamera
	if camera then
		local inset: Vector2 = GuiService:GetGuiInset()
		local unitRay = camera:ViewportPointToRay(mouse.X, mouse.Y + inset.Y)
		local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 10000, self.raycastParams)
		local hit = result and result.Position or unitRay.Origin + (unitRay.Direction * 10000)

		-- rotate turret to the mouse hit position
		self.rotationUtil:rotateTurret(hit, deltaTime)
	end

	-- play traverse sounds (yes it was more complicated than i expected)
	self.traverseUtil:update(deltaTime)

	-- replicate turret rotation to other players, using speed setting from the config
	local resolution = TurretConfig.ReplicationResolution
	self.timeAccumulator = self.timeAccumulator + deltaTime
	if self.timeAccumulator >= resolution then
		local x0, y0, z0 = self.turretInfo.YawMotor.C0:ToOrientation()
		local yawRotation = Vector3.new(x0, y0, z0)
		local x1, y1, z1 = self.turretInfo.PitchMotor.C0:ToOrientation()
		local pitchRotation = Vector3.new(x1, y1, z1)
		local sensivity = 0.005
		if (yawRotation - self.lastYawRotation).Magnitude > sensivity or (pitchRotation - self.lastPitchRotation).Magnitude > sensivity then
			replicationRemote:FireServer(yawRotation, pitchRotation)
			self.lastYawRotation = yawRotation
			self.lastPitchRotation = pitchRotation
		end

		self.timeAccumulator -= resolution
	end

	-- draw debug ray if enabled
	if TurretConfig.Debug then
		local pitchTarget = self.turretInfo.PitchMotor.Part1
		local origin = pitchTarget.Position
		local direction = pitchTarget.CFrame.LookVector * 10000
		local result = workspace:Raycast(origin, direction, self.raycastParams)
		local hitPosition = result and result.Position or (origin + direction)
		funcs.renderDebugRay(self, origin, hitPosition)
	end
end

function funcs.renderDebugRay(self: SelfObject, origin: Vector3, goal: Vector3)
	local self = self :: SelfObject
	if not self.debugRayPart then self.debugRayPart = funcs.createDebugRayPart() end

	local rayDir = goal - origin
	local distance = rayDir.Magnitude
	if distance > 0.01 then
		local midPoint = origin + rayDir * 0.5
		self.debugRayPart.Size = Vector3.new(0.05, 0.05, distance)
		self.debugRayPart.CFrame = CFrame.lookAt(midPoint, goal)
		self.debugRayPart.Transparency = 0
	else
		self.debugRayPart.Transparency = 1
	end
end

function funcs.createDebugRayPart(): Part
	local debugPart = Instance.new("Part")
	debugPart.Name = "TurretDebugRay"
	debugPart.Anchored = true
	debugPart.CanCollide = false
	debugPart.CanQuery = false
	debugPart.CanTouch = false
	debugPart.CastShadow = false
	debugPart.Material = Enum.Material.Neon
	debugPart.Color = Color3.new(1, 0, 0)
	debugPart.Parent = workspace
	return debugPart
end

return module
