--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTS INTERNAL
local TurretStateService = require(script.Parent.TurretStateService)

-- ROBLOX OBJECTS
-- SHARED
local replicationRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ReplicateState

-- handles turret rotation replication
function funcs.handleReplicateTurretState(player: Player, yawRotationC0: Vector3, pitchRotationC0: Vector3)
	assert(typeof(yawRotationC0) == "Vector3" and typeof(pitchRotationC0) == "Vector3")
	local turretInfo = TurretStateService.getPlayerCurrentTurret(player)
	if not turretInfo or not turretInfo.TurretModel.Parent then return end --assert(turretInfo) will flood console
	turretInfo.YawMotor.C0 = CFrame.new(turretInfo.YawMotor.C0.Position) * CFrame.fromOrientation(yawRotationC0.X, yawRotationC0.Y, yawRotationC0.Z)
	turretInfo.PitchMotor.C0 = CFrame.new(turretInfo.PitchMotor.C0.Position) * CFrame.fromOrientation(pitchRotationC0.X, pitchRotationC0.Y, pitchRotationC0.Z)
end

-- SUBSCRIPTIONS
replicationRemote.OnServerEvent:Connect(funcs.handleReplicateTurretState)

return module