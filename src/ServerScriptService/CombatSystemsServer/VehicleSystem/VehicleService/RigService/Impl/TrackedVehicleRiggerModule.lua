--!strict

local module = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleConfigUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleConfigUtilModule)
local RigUtil = require(ServerScriptService.CombatSystemsServer.Utils.RigUtilModule)

-- IMPORTS INTERNAL
local VehicleRigUtil = require(script.Parent.Parent.RigUtilModule)

function module.rigVehicle(vehicle: Model, vehicleConfig: VehicleConfigUtil.DefaultType, chassis: BasePart, totalMass: number)
	local tracks = vehicle:FindFirstChild("Tracks")
	assert(tracks, "Tracks model not found")
	RigUtil.clearWelds(tracks)

	-- rig tracks
	local wheels: { BasePart } = {}
	for _, descendant: Instance in ipairs(vehicle:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:HasTag("Wheel") then table.insert(wheels, descendant :: BasePart) end
	end
	assert(#wheels > 0, "Tracked vehicle has no wheels")

	-- constraint wheels
	for _, wheel in ipairs(wheels) do
		VehicleRigUtil.constraintWheel(vehicleConfig, chassis, totalMass, #wheels, wheel)
	end
end

return module
