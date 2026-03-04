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
local playerGui = player.PlayerGui
local hudGui = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("VehicleSystemGui"):WaitForChild("VehicleHud") :: ScreenGui
local container = hudGui:WaitForChild("Container") :: any

-- FINALS
local cleaner = ConnectionCleaner.new()

-- PUBLIC EVENTS
module.VehicleHudEnabled = Signal.new()
module.VehicleHudDisabled = Signal.new()

-- INTERNAL FUNCTIONS
function funcs.onVehicleViewSet(vehicleInfo: VehicleUtil.VehicleInfo)
	local vehicleInfoFrame = container.VehicleInfo :: any
	local topInfoBar = vehicleInfoFrame.TopInfoBar
	topInfoBar.VehicleName.Text = vehicleInfo.VehicleModel.Name
	topInfoBar.VehicleDescription.Text = vehicleInfo.VehicleConfig.Description

	local healthBar = vehicleInfoFrame.HealthBar
	local function updateHealthBar()
		local remainingHealthPercentage = vehicleInfo.VehicleObject:getHealth() / vehicleInfo.VehicleObject:getMaxHealth()
		if remainingHealthPercentage > 0.6 then
			healthBar.Value.BackgroundColor3 = healthBar.Value.HighHealth.Value
		elseif remainingHealthPercentage > 0.3 then
			healthBar.Value.BackgroundColor3 = healthBar.Value.MediumHealth.Value
		else
			healthBar.Value.BackgroundColor3 = healthBar.Value.LowHealth.Value
		end

		healthBar.HealthText.Text = tostring(math.round(vehicleInfo.VehicleObject:getHealth() * 10) / 10) .. "/" .. tostring(vehicleInfo.VehicleObject:getMaxHealth())
		healthBar.Value.Size = UDim2.fromScale(vehicleInfo.VehicleObject:getHealth() / vehicleInfo.VehicleObject:getMaxHealth(), 1)
	end
	updateHealthBar()

	cleaner:add(vehicleInfo.VehicleObject.HealthChanged:Connect(function()
		updateHealthBar()
	end))

	cleaner:add(RunService.RenderStepped:Connect(function()
		vehicleInfoFrame.Speed.Text = "SPD: " .. tostring(math.round(vehicleInfo.DriverSeat.AssemblyLinearVelocity.Magnitude)) .. " / " .. tostring(vehicleInfo.VehicleConfig.MovementConfig.MaxSpeed) .. " sps"
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
	hudGui = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("VehicleSystemGui"):WaitForChild("VehicleHud") :: ScreenGui
	container = hudGui:WaitForChild("Container") :: Frame
end)

return module