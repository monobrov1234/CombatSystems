--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleConfigUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleConfigUtil)
local RigUtil = require(ServerScriptService.CombatSystemsServer.Utils.RigUtil)

-- IMPORTS INTERNAL
local VehicleRigUtil = require(script.Parent.Parent.VehicleRigUtil)
local VehicleRigService = require(script.Parent.Parent.VehicleRigService)

-- INTERNAL FUNCTIONS
function funcs.handleTypeRigRequested(vehicle: Model, vehicleConfig: VehicleConfigUtil.DefaultType, chassis: BasePart, totalMass: number)
	if vehicleConfig.ConfigType ~= "Normal" then return end

	local wheelsModel = vehicle:FindFirstChild("Wheels")
	assert(wheelsModel, "Wheels model not found")
	RigUtil.clearWelds(wheelsModel)

	local wheels: { BasePart } = {}
	for _, descendant: Instance in ipairs(vehicle:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:HasTag("Wheel") then table.insert(wheels, descendant :: BasePart) end
	end
	assert(#wheels > 0, "Vehicle has no wheels")

	for _, wheel in ipairs(wheels) do
		local rootAttachment = VehicleRigUtil.constraintWheel(vehicleConfig, chassis, totalMass, #wheels, wheel)
		local steerDirection = wheel:GetAttribute("SteeringDirection")
		if steerDirection then rootAttachment.Name = steerDirection == "L" and "AttachmentSL" or "AttachmentSR" end
	end
end

-- SUBSCRIPTIONS
VehicleRigService.TypeRigRequested:connect(funcs.handleTypeRigRequested)

return module
