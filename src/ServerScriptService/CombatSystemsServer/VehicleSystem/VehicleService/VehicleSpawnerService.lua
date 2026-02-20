--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PlayerTeamCheckUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.PlayerTeamCheckUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig)
local VehicleSpawnerConfigUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleSpawnerConfigUtil)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local VehicleSpawnerConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSpawnerConfig)
local PlayerGroupService = require(ServerScriptService.CombatSystemsServer.PlayerGroupService)

-- IMPORTS INTERNAL
local VehicleSpawnService = require(script.Parent.VehicleSpawnService)

-- ROBLOX OBJECTS
-- S->C
local openGuiRemote: RemoteEvent = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.SpawnerService.ServerToClient.OpenSpawnerGui

-- C->S
local useSpawnerRemote: RemoteEvent = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.SpawnerService.ClientToServer.UseSpawner

-- FINALS
local spawnerDelayMap = {} :: { [BasePart]: number }

-- INTERNAL FUNCTIONS
function funcs.handleSpawnerTriggered(player: Player, spawner: BasePart, config: VehicleSpawnerConfigUtil.DefaultType)
	if not funcs.checkPlayer(player, config) then return end
	if funcs.checkSpawnerOnCooldown(spawner, config) then return end
	openGuiRemote:FireClient(player, spawner)
end

function funcs.handleUseSpawner(player: Player, spawner: BasePart, vehicleName: string)
	assert(typeof(player) == "Instance" and typeof(spawner) == "Instance" and typeof(vehicleName) == "string")
	assert(spawner:IsA("BasePart"))

	local config: VehicleSpawnerConfigUtil.DefaultType = VehicleSpawnerConfigUtil.parseSpawnerConfig(spawner)
	assert(table.find(config.Spawnables, vehicleName))

	if not funcs.checkPlayer(player, config) then return end
	if funcs.checkSpawnerOnCooldown(spawner, config) then return end

	local character: Model? = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	assert(rootPart and rootPart:IsA("BasePart"))

	local distance = (spawner.Position - rootPart.Position).Magnitude
	if distance > config.MaxUseDistance then return end

	local vehicleModel = VehicleSystemConfig.Folder:FindFirstChild(vehicleName) :: Model
	assert(vehicleModel, "Spawnable vehicle model not found in workspace")

	local _, volume = vehicleModel:GetBoundingBox()
	assert(volume)

	local offset = CFrame.new(volume.Z / 2, volume.Y / 2, 0)
	offset *= CFrame.new(config.PositionOffset)
	offset *= CFrame.fromOrientation(math.rad(config.RotationOffset.X), math.rad(config.RotationOffset.Y), math.rad(config.RotationOffset.Z))
	local spawnCFrame = spawner.CFrame * offset

	local parts: { BasePart } = workspace:GetPartBoundsInBox(spawnCFrame, volume)
	for _, part: BasePart in ipairs(parts) do
		local currentAncestor: Instance = part
		while currentAncestor.Parent do
			if currentAncestor:IsA("Model") and VehicleUtil.validateVehicle(currentAncestor) then
				if config.ForceDestroyObstruction then
					currentAncestor:Destroy()
					break
				else
					local seat: VehicleSeat? = currentAncestor:FindFirstChildOfClass("VehicleSeat")
					assert(seat)

					if not seat.Occupant then
						currentAncestor:Destroy()
						break
					else
						return
					end
				end
			end
			currentAncestor = currentAncestor.Parent
		end
	end

	VehicleSpawnService.requestSpawn(vehicleModel, spawnCFrame)

	spawnerDelayMap[spawner] = os.clock()
	spawner.Color = config.DisabledColor
	task.delay(config.Delay, function()
		spawner.Color = config.EnabledColor :: Color3
	end)
end

function funcs.rigAllSpawners()
	for _, spawner: Instance in ipairs(CollectionService:GetTagged(VehicleSpawnerConfig.Tag)) do
		assert(spawner:IsA("BasePart"))

		local config = VehicleSpawnerConfigUtil.parseSpawnerConfig(spawner)
		local prompt: ProximityPrompt = VehicleSystemConfig.BasePrompt:Clone()
		prompt.ObjectText = spawner.Name
		prompt.ActionText = "Open menu"
		prompt.HoldDuration = VehicleSpawnerConfig.PromptDuration
		prompt.Triggered:Connect(function(player: Player)
			funcs.handleSpawnerTriggered(player, spawner, config)
		end)
		prompt.Parent = spawner
	end
end

function funcs.checkPlayer(player: Player, config: VehicleSpawnerConfigUtil.DefaultType): boolean
	if config.GroupWhitelist and not PlayerGroupService.isInAnyWhitelistedGroup(player, config.GroupWhitelist) then return false end
	if config.TeamWhitelist and not PlayerTeamCheckUtil.isInAnyWhitelistedTeam(player, config.TeamWhitelist) then return false end
	return true
end

function funcs.checkSpawnerOnCooldown(spawner: BasePart, config: VehicleSpawnerConfigUtil.DefaultType): boolean
	local lastSpawnTime: number? = spawnerDelayMap[spawner]
	if not lastSpawnTime then return false end
	return os.clock() - lastSpawnTime < config.Delay
end

-- SUBSCRIPTIONS
funcs.rigAllSpawners()
useSpawnerRemote.OnServerEvent:Connect(funcs.handleUseSpawner)

return module
