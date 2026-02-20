--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)

-- IMPORTS INTERNAL
local VehicleRigService = require(script.Parent.RigService.VehicleRigService)

-- PUBLIC API
function module.requestSpawn(vehicleModel: Model, cframe: CFrame)
	VehicleUtil.parseVehicleInfoNonRig(vehicleModel)

	local vehicleClone: Model = vehicleModel:Clone()
	vehicleClone:PivotTo(cframe)

	local vehicleCloneInfoNonRig: VehicleUtil.VehicleInfoNotRigged = VehicleUtil.parseVehicleInfoNonRig(vehicleClone)
	VehicleRigService.rigVehicle(vehicleCloneInfoNonRig)

	local wheels: { BasePart } = VehicleRigService.findWheels(vehicleClone)
	for _, wheel: BasePart in ipairs(wheels) do
		for _, descendant: Instance in ipairs(wheel:GetDescendants()) do
			if descendant:IsA("BasePart") then descendant.Anchored = false end
		end
		wheel.Anchored = false
	end

	vehicleClone.Parent = workspace

	-- TODO: rewrite delayed unanchor
	task.wait(0.5)

	for _, descendant: Instance in ipairs(vehicleClone:GetDescendants()) do
		if descendant:IsA("BasePart") then descendant.Anchored = false end
	end
end

return module
