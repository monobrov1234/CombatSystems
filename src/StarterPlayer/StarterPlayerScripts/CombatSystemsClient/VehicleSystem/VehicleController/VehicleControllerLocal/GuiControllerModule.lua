local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleanerModule)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local character = player.Character or player.CharacterAdded:Wait()

local guiRoot = playerGui:WaitForChild("CombatSystemsGui")
local vehicleSystemGui = guiRoot:WaitForChild("VehicleSystemGui")
local hudGui = vehicleSystemGui:WaitForChild("VehicleHud")

-- FINALS
local cleaner = ConnectionCleaner.new()

-- STATE
local healthUpdateConnection: RBXScriptConnection

function module.enableGui(vehicleInfo: VehicleUtil.VehicleInfo)
	local main = hudGui.DriversHud.Main
	main.Title.Text = vehicleInfo.VehicleModel.Name
	main.VType.Text = vehicleInfo.VehicleConfig.Description
	main.Health.Text = math.round(vehicleInfo.VehicleObject:getHealth() * 10) / 10 -- round to 1 decimal places
	main.MaxHealth.Text = vehicleInfo.VehicleObject:getMaxHealth()

	cleaner:add(vehicleInfo.VehicleObject.HealthChanged:Connect(function()
		main.Health.Text = math.round(vehicleInfo.VehicleObject:getHealth() * 10) / 10 -- round to 1 decimal places
	end))
	cleaner:add(RunService.RenderStepped:Connect(function()
		main.Speedometer.Text = "SPD: " .. tostring(math.round(vehicleInfo.DriverSeat.AssemblyLinearVelocity.Magnitude))
	end))

	hudGui.Enabled = true
end

function module.disableGui()
	cleaner:disconnectAll()
	hudGui.Enabled = false
end

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	guiRoot = playerGui:WaitForChild("CombatSystemsGui")
	vehicleSystemGui = guiRoot:WaitForChild("VehicleSystemGui")
	hudGui = vehicleSystemGui:WaitForChild("VehicleHud")
end)

return module
