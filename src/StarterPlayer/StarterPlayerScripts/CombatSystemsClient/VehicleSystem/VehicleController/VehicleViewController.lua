--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- STATE
local vehicleInfo: VehicleUtil.VehicleInfo?

-- PUBLIC EVENTS
module.VehicleViewSet = Signal.new()
module.VehicleViewCleared = Signal.new()

-- PUBLIC API
function module.setVehicleView(info: VehicleUtil.VehicleInfo?)
	if not info then
		funcs.clearVehicleView()
		return
	end
	vehicleInfo = info
	module.VehicleViewSet:fire(info)
end

function module.getCurrentVehicleInfo(): VehicleUtil.VehicleInfo?
	return vehicleInfo
end

-- INTERNAL FUNCTIONS
function funcs.clearVehicleView()
	vehicleInfo = nil
	module.VehicleViewCleared:fire()
end

return module
