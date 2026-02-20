--!strict

local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleSpawnerConfigPath = ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSpawnerConfig
local VehicleSpawnerConfigTemplate = require(VehicleSpawnerConfigPath.Config)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer :: Player
local playerGui = player.PlayerGui
local _character = player.Character or player.CharacterAdded:Wait()

-- gui
local spawnerGui = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("VehicleSystemGui"):WaitForChild("SpawnerGui")

-- remotes
local openGuiRemote: RemoteEvent = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.SpawnerService.ServerToClient.OpenSpawnerGui
local useSpawnerRemote: RemoteEvent = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.SpawnerService.ClientToServer.UseSpawner

-- STATE
local currentGui: ScreenGui?

function funcs.handleOpenRemote(spawner: BasePart)
	local spawnerTransform = (spawner :: any) :: typeof(VehicleSpawnerConfigPath) -- for require line below not to be red
	local configModule = spawnerTransform:FindFirstChild("Config")
	assert(configModule and configModule:IsA("ModuleScript"), "Spawner config not found")
	local config = require(configModule) :: typeof(VehicleSpawnerConfigTemplate)
	funcs.openSpawnerGui(spawner, config)
end

function funcs.openSpawnerGui(spawner: BasePart, config: typeof(VehicleSpawnerConfigTemplate))
	funcs.closeSpawnerGui()

	local clone = spawnerGui:Clone()
	clone.Container.CloseButton.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then funcs.closeSpawnerGui() end
	end)

	for _, vehicleName: string in ipairs(config.Spawnables) do
		local templateClone = clone.Container.MainFrame.ScrollingFrame.Template:Clone()
		templateClone.Text = vehicleName
		templateClone.Name = vehicleName
		templateClone.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then funcs.handleItemClick(spawner, vehicleName) end
		end)
		templateClone.Visible = true
		templateClone.Parent = clone.Container.MainFrame.ScrollingFrame
	end

	clone.Enabled = true
	clone.Parent = spawnerGui.Parent
	currentGui = clone
end

function funcs.handleItemClick(spawner: BasePart, vehicleName: string)
	useSpawnerRemote:FireServer(spawner, vehicleName)
	funcs.closeSpawnerGui()
end

function funcs.closeSpawnerGui()
	if not currentGui then return end
	currentGui:Destroy()
	currentGui = nil
end

openGuiRemote.OnClientEvent:Connect(funcs.handleOpenRemote)

player.CharacterAdded:Connect(function(newCharacter: Model)
	_character = newCharacter
	spawnerGui = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("VehicleSystemGui"):WaitForChild("SpawnerGui")
end)
