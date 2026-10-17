-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- RotationUtil only uses TurretUtil for a type. Avoid loading the turret
-- config tree while testing its rotation math.
JestGlobals.jest.mock(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil, function()
	return {}
end)

local RotationUtil = require(
	StarterPlayer.StarterPlayerScripts.CombatSystemsClient.TurretSystem.TurretController.Util.RotationUtil
)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("RotationUtil", function()
	it("steps turret yaw toward its target at the configured speed", function()
		local model = Instance.new("Model")
		local yawBase = Instance.new("Part")
		local pitchBase = Instance.new("Part")
		local yawMotor = Instance.new("Motor6D")
		local pitchMotor = Instance.new("Motor6D")
		yawBase.Parent = model
		pitchBase.Parent = model
		local yawPart = Instance.new("Part")
		yawPart.Parent = model
		local pitchPart = Instance.new("Part")
		pitchPart.Parent = model
		yawMotor.Part0 = yawBase
		yawMotor.Part1 = yawPart
		pitchMotor.Part0 = pitchBase
		pitchMotor.Part1 = pitchPart
		yawMotor.Parent = model
		pitchMotor.Parent = model

		local turretInfo = {
			YawMotor = yawMotor,
			PitchMotor = pitchMotor,
			TurretConfig = {
				LimitsConfig = {
					YawSpeed = 90,
					YawCenter = 0,
					YawLeftLimit = 180,
					YawRightLimit = 180,
					PitchSpeed = 90,
					PitchCenter = 0,
					PitchDownLimit = 90,
					PitchUpLimit = 90,
				},
			},
		} :: any
		local rotation = RotationUtil.new(turretInfo)

		rotation:rotateTurret(Vector3.new(100, 0, -100), 0.1)

		local _, yaw = yawMotor.C0:ToOrientation()
		expect(math.abs(math.deg(yaw) - -9) < 1e-4).toBe(true)
		model:Destroy()
	end)

	it("initializes its current motor offsets from the turret", function()
		local yawC0 = CFrame.new(1, 2, 3) * CFrame.Angles(0, math.rad(15), 0)
		local pitchC0 = CFrame.new(4, 5, 6) * CFrame.Angles(math.rad(-5), 0, 0)
		local turretInfo = {
			YawMotor = { C0 = yawC0 },
			PitchMotor = { C0 = pitchC0 },
		} :: any

		local rotation = RotationUtil.new(turretInfo)

		expect(rotation.currentYawC0).toEqual(yawC0)
		expect(rotation.currentPitchC0).toEqual(pitchC0)
	end)
end)
