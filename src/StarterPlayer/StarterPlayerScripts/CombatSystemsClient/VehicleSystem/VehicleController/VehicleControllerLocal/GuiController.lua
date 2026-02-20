--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- IMPORTS INTERNAL
local VehicleViewController = require(script.Parent.VehicleViewController)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")
local guiRoot = playerGui:WaitForChild("CombatSystemsGui")
local vehicleSystemGui = guiRoot:WaitForChild("VehicleSystemGui")
local hudGui = vehicleSystemGui:WaitForChild("VehicleHud")

-- FINALS
local cleaner = ConnectionCleaner.new()

-- PUBLIC EVENTS
module.VehicleHudEnabled = Signal.new()
module.VehicleHudDisabled = Signal.new()

-- INTERNAL FUNCTIONS
function funcs.onVehicleViewSet(vehicleInfo: VehicleUtil.VehicleInfo)
	local main = hudGui.DriversHud.Main
	main.Title.Text = vehicleInfo.VehicleModel.Name
	main.VType.Text = vehicleInfo.VehicleConfig.Description
	main.Health.Text = math.round(vehicleInfo.VehicleObject:getHealth() * 10) / 10
	main.MaxHealth.Text = vehicleInfo.VehicleObject:getMaxHealth()

	cleaner:add(vehicleInfo.VehicleObject.HealthChanged:Connect(function()
		main.Health.Text = math.round(vehicleInfo.VehicleObject:getHealth() * 10) / 10
	end))
	cleaner:add(RunService.RenderStepped:Connect(function()
		main.Speedometer.Text = "SPD: " .. tostring(math.round(vehicleInfo.DriverSeat.AssemblyLinearVelocity.Magnitude))
	end))

	hudGui.Enabled = true
	module.VehicleHudEnabled:fire()
end

function funcs.onVehicleViewCleared()
	cleaner:disconnectAll()
	hudGui.Enabled = false
	module.VehicleHudDisabled:fire()
end

-- SUBSCRIPTIONS
VehicleViewController.VehicleViewSet:connect(funcs.onVehicleViewSet)
VehicleViewController.VehicleViewCleared:connect(funcs.onVehicleViewCleared)

player.CharacterAdded:Connect(function()
	guiRoot = playerGui:WaitForChild("CombatSystemsGui")
	vehicleSystemGui = guiRoot:WaitForChild("VehicleSystemGui")
	hudGui = vehicleSystemGui:WaitForChild("VehicleHud")
end)

return module
