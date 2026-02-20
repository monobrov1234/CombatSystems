--!strict

local module = {}
local funcs = {}
module.__index = module

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
local VehicleRigService = require(ServerScriptService.CombatSystemsServer.VehicleSystem.VehicleService.RigService.VehicleRigService)

-- ROBLOX OBJECTS
-- remotes
local openGuiRemote: RemoteEvent = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.SpawnerService.ServerToClient.OpenSpawnerGui
local useSpawnerRemote: RemoteEvent = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.SpawnerService.ClientToServer.UseSpawner

-- FINALS
local spawnerDelayMap = {} :: { [BasePart]: number }

-- PUBLIC API
function module.spawnVehicle(vehicleModel: Model, cframe: CFrame)
	VehicleUtil.parseVehicleInfoNonRig(vehicleModel) -- validate vehicle
	local vehicleClone: Model = vehicleModel:Clone()
	vehicleClone:PivotTo(cframe)

	-- rig vehicle
	local vehicleCloneInfoNonRig: VehicleUtil.VehicleInfoNotRigged = VehicleUtil.parseVehicleInfoNonRig(vehicleClone)
	VehicleRigService.rigVehicle(vehicleCloneInfoNonRig)

	-- spawn vehicle
	local wheels: { BasePart } = VehicleRigService.findWheels(vehicleClone)
	for _, wheel: BasePart in ipairs(wheels) do
		for _, descendant: Instance in ipairs(wheel:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = false
			end
		end
		wheel.Anchored = false
	end

	vehicleClone.Parent = workspace

	-- TODO: rewrite
	task.wait(0.5)

	for _, descendant: Instance in ipairs(vehicleClone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end
end

-- INTERNAL FUNCTIONS
-- spawner core functionality
function funcs.handleSpawnerTriggered(player: Player, spawner: BasePart, config: VehicleSpawnerConfigUtil.DefaultType)
	if not funcs.checkPlayer(player, config) then return end
	if funcs.checkSpawnerOnCooldown(spawner, config) then return end
	openGuiRemote:FireClient(player, spawner)
end

-- remote event
function funcs.handleUseSpawner(player: Player, spawner: BasePart, vehicleName: string)
	assert(typeof(player) == "Instance" and typeof(spawner) == "Instance" and typeof(vehicleName) == "string")
	assert(spawner:IsA("BasePart"))
	local config: VehicleSpawnerConfigUtil.DefaultType = VehicleSpawnerConfigUtil.parseSpawnerConfig(spawner)
	assert(table.find(config.Spawnables, vehicleName)) -- that vehicle should be in the spawnable vehicles list in the spawner config

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

	-- calculate spawn position
	local _, volume = vehicleModel:GetBoundingBox()
	assert(volume)

	local offset = CFrame.new(volume.Z / 2, volume.Y / 2, 0)
	offset *= CFrame.new(config.PositionOffset) -- add positon offset
	offset *= CFrame.fromOrientation(math.rad(config.RotationOffset.X), math.rad(config.RotationOffset.Y), math.rad(config.RotationOffset.Z)) -- add rotation offset
	local spawnCFrame = spawner.CFrame * offset

	-- check for obstructions
	local parts: { BasePart } = workspace:GetPartBoundsInBox(spawnCFrame, volume)
	for _, part: BasePart in ipairs(parts) do
		local currentAncestor: Instance = part
		while currentAncestor.Parent do
			if currentAncestor:IsA("Model") and VehicleUtil.validateVehicle(currentAncestor) then
				-- found vehicle that is obstructing our way
				if config.ForceDestroyObstruction then
					-- force enabled, directly destroy it
					currentAncestor:Destroy()
					break
				else
					-- force disabled
					local seat: VehicleSeat? = currentAncestor:FindFirstChildOfClass("VehicleSeat")
					assert(seat)
					if not seat.Occupant then
						-- this vehicle has no occupant, destroy
						currentAncestor:Destroy()
						break
					else
						-- this vehicle has occupant, don't destroy and return
						return
					end
				end
			end
			currentAncestor = currentAncestor.Parent
		end
	end

	module.spawnVehicle(vehicleModel, spawnCFrame)

	spawnerDelayMap[spawner] = os.clock()
	spawner.Color = config.DisabledColor
	task.delay(config.Delay, function()
		spawner.Color = config.EnabledColor :: Color3
	end)
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

-- will scan, rig, and hook every part with spawner tag in workspace
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
funcs.rigAllSpawners()

useSpawnerRemote.OnServerEvent:Connect(funcs.handleUseSpawner)

return module
