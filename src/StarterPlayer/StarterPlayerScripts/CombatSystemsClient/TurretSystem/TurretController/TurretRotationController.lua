--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TurretStateController = require(script.Parent.TurretStateController)
local CursorController = require(PlayerScripts.CombatSystemsClient.MunitionSystem.ClientFX.CursorController)
local TurretSystemConfig = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.TurretSystemConfig)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)

-- IMPORTS INTERNAL
local RotationUtil = require(script.Parent.Util.RotationUtil)
local TraverseUtil = require(script.Parent.Util.TraverseUtil)
local TurretViewController = require(script.Parent.TurretViewController)

-- ROBLOX OBJECTS
local mouse = player:GetMouse()
-- C->S
local replicationRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ReplicateState

-- FINALS
local cleaner = ConnectionCleaner.new()

-- STATE
local turretInfo: TurretUtil.TurretInfo?
local raycastParams: RaycastParams?
local rotationUtil: RotationUtil.SelfObject?
local traverseUtil: TraverseUtil.SelfObject?

local debugRayPart: Part?
local lastYawRotation = Vector3.new(math.huge, math.huge, math.huge)
local lastPitchRotation = Vector3.new(math.huge, math.huge, math.huge)
local timeAccumulator = 0.0

-- INTERNAL FUNCTIONS
function funcs.handleTurretViewSet(newTurretInfo: TurretUtil.TurretInfo)
	raycastParams = TurretStateController.getCurrentRaycastParams()
	assert(raycastParams)

	turretInfo = newTurretInfo
	rotationUtil = RotationUtil.new(newTurretInfo)
	local yawBase = newTurretInfo.YawMotor.Part0
	traverseUtil = TraverseUtil.new(
		newTurretInfo,
		nil,
		nil,
		yawBase and yawBase:FindFirstChild("TraverseStart") :: Sound?,
		yawBase and yawBase:FindFirstChild("Traverse") :: Sound?,
		yawBase and yawBase:FindFirstChild("TraverseEnd") :: Sound?
	)

	cleaner:disconnectAll()
	cleaner:add(RunService.PreSimulation:Connect(function(deltaTime: number)
		funcs.updateTurretRotation(deltaTime)
	end))
	cleaner:add(RunService.Heartbeat:Once(function()
		CursorController.enableCursor()
	end))
end

function funcs.handleTurretViewCleared()
	cleaner:disconnectAll()

	if debugRayPart then
		debugRayPart:Destroy()
		debugRayPart = nil
	end
	if traverseUtil then
		traverseUtil:destroy()
		traverseUtil = nil
	end

	rotationUtil = nil
	turretInfo = nil
	raycastParams = nil
	lastYawRotation = Vector3.new(math.huge, math.huge, math.huge)
	lastPitchRotation = Vector3.new(math.huge, math.huge, math.huge)
	timeAccumulator = 0
end

function funcs.updateTurretRotation(deltaTime: number)
	if not turretInfo or not raycastParams or not rotationUtil or not traverseUtil then return end
	if not turretInfo.TurretModel.Parent then return end

	local camera = workspace.CurrentCamera
	local inset: Vector2 = GuiService:GetGuiInset()
	local unitRay = camera:ViewportPointToRay(mouse.X, mouse.Y + inset.Y)
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 10000, raycastParams)
	local hit = result and result.Position or unitRay.Origin + (unitRay.Direction * 10000)
	rotationUtil:rotateTurret(hit, deltaTime)

	traverseUtil:update(deltaTime)

	local resolution = TurretSystemConfig.ReplicationResolution
	timeAccumulator = timeAccumulator + deltaTime
	if timeAccumulator >= resolution then
		local x0, y0, z0 = turretInfo.YawMotor.C0:ToOrientation()
		local yawRotation = Vector3.new(x0, y0, z0)
		local x1, y1, z1 = turretInfo.PitchMotor.C0:ToOrientation()
		local pitchRotation = Vector3.new(x1, y1, z1)
		local sensivity = 0.005
		if (yawRotation - lastYawRotation).Magnitude > sensivity or (pitchRotation - lastPitchRotation).Magnitude > sensivity then
			replicationRemote:FireServer(yawRotation, pitchRotation)
			lastYawRotation = yawRotation
			lastPitchRotation = pitchRotation
		end
		timeAccumulator -= resolution
	end

	if TurretSystemConfig.Debug then
		local pitchTarget = turretInfo.PitchMotor.Part1
		if pitchTarget then
			local origin = pitchTarget.Position
			local direction = pitchTarget.CFrame.LookVector * 10000
			result = workspace:Raycast(origin, direction, raycastParams)
			local hitPosition = result and result.Position or (origin + direction)
			funcs.renderDebugRay(origin, hitPosition)
		end
	end
end

function funcs.renderDebugRay(origin: Vector3, goal: Vector3)
	if not debugRayPart then debugRayPart = funcs.createDebugRayPart() end
	assert(debugRayPart)

	local rayDir = goal - origin
	local distance = rayDir.Magnitude
	if distance > 0.01 then
		local midPoint = origin + rayDir * 0.5
		debugRayPart.Size = Vector3.new(0.05, 0.05, distance)
		debugRayPart.CFrame = CFrame.lookAt(midPoint, goal)
		debugRayPart.Transparency = 0
	else
		debugRayPart.Transparency = 1
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

-- SUBSCRIPTIONS
TurretViewController.TurretViewSet:connect(funcs.handleTurretViewSet)
TurretViewController.TurretViewCleared:connect(funcs.handleTurretViewCleared)

return module
