--!strict

local module = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleConfigUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleConfigUtil)
local RigUtil = require(ServerScriptService.CombatSystemsServer.Utils.RigUtil)

-- IMPORTS INTERNAL
local VehicleRigUtil = require(script.Parent.Parent.VehicleRigUtil)

function module.rigVehicle(vehicle: Model, vehicleConfig: VehicleConfigUtil.DefaultType, chassis: BasePart, totalMass: number)
	local wheelsModel = vehicle:FindFirstChild("Wheels")
	assert(wheelsModel, "Wheels model not found")
	RigUtil.clearWelds(wheelsModel)

	-- rig wheels
	local wheels: { BasePart } = {}
	for _, descendant: Instance in ipairs(vehicle:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:HasTag("Wheel") then table.insert(wheels, descendant :: BasePart) end
	end
	assert(#wheels > 0, "Vehicle has no wheels")

	-- constraint wheels
	for _, wheel in ipairs(wheels) do
		local rootAttachment, wheelAttachment, spring, motor = VehicleRigUtil.constraintWheel(vehicleConfig, chassis, totalMass, #wheels, wheel)
		local steerDirection = wheel:GetAttribute("SteeringDirection")
		if steerDirection then rootAttachment.Name = steerDirection == "L" and "AttachmentSL" or "AttachmentSR" end
	end
end

return module
