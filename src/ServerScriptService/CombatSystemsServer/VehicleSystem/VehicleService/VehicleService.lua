--!strict

--[[
    Vehicle Service (Server-Side)
]]

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local PlayerGroupService = require(ServerScriptService.CombatSystemsServer.PlayerGroupService)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)

-- IMPORTS INTERNAL
local SpawnerService = require(script.Parent.SpawnerService)
local VehicleRigService = require(script.Parent.RigService.VehicleRigService)

-- ROBLOX OBJECTS
local setOwnershipRemote = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.ClientToServer.SetVehicleOwnership
local adminDeleteRemote = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.AdminTools.ClientToServer.DeleteVehicle
local adminSpawnRemote = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.AdminTools.ClientToServer.SpawnVehicle

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleService")

-- SpawnerService.DriverPromptTriggered
function funcs.handleDriverPromptTriggered(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt)
	funcs.handlePromptGeneric(player, vehicleInfo, prompt, vehicleInfo.DriverSeat, vehicleInfo.VehicleConfig.SeatConfig.DriverGroupWhitelist)
end

-- SpawnerService.PassengerPromptTriggered
function funcs.handlePassengerPromptTriggered(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt, seat: Seat)
	funcs.handlePromptGeneric(player, vehicleInfo, prompt, seat, vehicleInfo.VehicleConfig.SeatConfig.PassengerGroupWhitelist)
end

function funcs.handlePromptGeneric(
	player: Player,
	vehicleInfo: VehicleUtil.VehicleInfo,
	prompt: ProximityPrompt,
	seat: Seat | VehicleSeat,
	groupWhitelist: { number }?
)
	local character = player.Character :: Model
	local vehicleAccessTool: Tool? = character:FindFirstChildOfClass("Tool")
	if not vehicleAccessTool or not vehicleAccessTool:HasTag(VehicleSystemConfig.VehicleAccessToolTag) then
		if groupWhitelist and not PlayerGroupService.isInAnyWhitelistedGroup(player, groupWhitelist) then return end
	end

	if funcs.trySitPlayer(player, seat) then
		prompt.Enabled = false
		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

		local cleaner = ConnectionCleaner.new()
		local cleaned = false
		local function resetPrompt()
			if cleaned then return end
			cleaned = true
			prompt.Enabled = true
			cleaner:disconnectAll()
			funcs.handleDismount(player, vehicleInfo, seat)
		end

		-- recheck memory leaks
		-- will re-enable the prompt if the player leaves his seat, guaranteed
		cleaner:add(humanoid.Seated:Connect(function(active: boolean)
			if not active then resetPrompt() end
		end)) -- humanoid left the seat
		cleaner:add(player.CharacterRemoving:Connect(function()
			resetPrompt()
		end)) -- character died
		cleaner:add(Players.PlayerRemoving:Connect(function(playerRemoving: Player)
			if playerRemoving == player then resetPrompt() end
		end)) -- player left
		funcs.handlePlayerSeated(player, vehicleInfo, seat)
	end
end

function funcs.handlePlayerSeated(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, seat: Seat | VehicleSeat)
	if seat ~= vehicleInfo.DriverSeat then return end
	-- play the enter vehicle sound
	funcs.playSound("Enter", seat)

	-- start the engine idle sound if it exists
	local engineIdle = (vehicleInfo.EnginePart :: BasePart):FindFirstChild("EngineIdle") :: Sound?
	if engineIdle then engineIdle:Play() end

	-- hook vehicle seat throttle changed event to play move sound
	local engineMove = (vehicleInfo.EnginePart :: BasePart):FindFirstChild("EngineMove") :: Sound?
	if engineMove then
		local seat = seat :: VehicleSeat
		local occupant = seat.Occupant
		assert(occupant)
		local connection: RBXScriptConnection
		connection = seat.Changed:Connect(function(property: string)
			if seat.Occupant ~= occupant then
				engineMove:Stop()
				connection:Disconnect()
				return
			end

			if property ~= "Throttle" then return end
			if seat.Throttle ~= 0 then
				engineMove:Play()
			else
				engineMove:Stop()
			end
		end)
	end
end

function funcs.handleDismount(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, seat: Seat | VehicleSeat)
	-- dismount player
	local dismountPart: BasePart
	if seat == vehicleInfo.DriverSeat then
		dismountPart = vehicleInfo.DismountPart
	else
		dismountPart = (seat :: any):FindFirstChild("DismountPart")
	end

	if dismountPart and dismountPart.Parent then
		local character: Model? = player.Character
		if character then
			local humanoidRootPart: Instance? = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart and humanoidRootPart:IsA("BasePart") then humanoidRootPart:PivotTo(dismountPart.CFrame) end
		end
	end

	-- play driver-specific sounds
	if seat ~= vehicleInfo.DriverSeat then return end

	-- play the dismount sound
	funcs.playSound("Dismount", seat)

	local enginePart: BasePart? = vehicleInfo.EnginePart
	if enginePart then
		-- stop the engine sound if it exists
		local engineIdle = enginePart:FindFirstChild("EngineIdle") :: Sound?
		if engineIdle then engineIdle:Stop() end
	end
end

function funcs.trySitPlayer(player: Player, seat: BasePart): boolean
	assert(seat:IsA("Seat") or seat:IsA("VehicleSeat"))
	if seat.Occupant then return false end -- someone is already sitting in this seat

	local character: Model? = player.Character
	if not character then return false end
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead or humanoid.SeatPart then return false end -- player is already sitting in some seat

	if seat:IsA("Seat") then
		seat:Sit(humanoid)
	elseif seat:IsA("VehicleSeat") then
		seat:Sit(humanoid)
	end

	return true
end

-- force set vehicle ownership to driver
-- TODO vulnerable method: can be spammed by the exploiter to lag the server
function funcs.handleSetOwnership(player: Player)
	log:debug("Handling set vehicle ownership event for player {}", player.Name)

	local character: Model? = player.Character
	assert(character)
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead)
	local seat: BasePart? = humanoid.SeatPart
	assert(seat and seat:IsA("VehicleSeat"))

	local vehicleModel: Instance? = seat.Parent
	assert(vehicleModel and vehicleModel:IsA("Model") and VehicleUtil.validateVehicle(vehicleModel))
	local primaryPart: BasePart? = vehicleModel.PrimaryPart
	assert(primaryPart)
	VehicleUtil.parseVehicleInfo(vehicleModel) -- validate vehicle

	primaryPart:SetNetworkOwner(player)
	log:debug("Successfully set player as a network owner for vehicle {}", vehicleModel.Name)

	local connection: RBXScriptConnection
	connection = humanoid.Seated:Connect(function(active: boolean, seatPart: BasePart)
		if active then return end
		connection:Disconnect()

		if vehicleModel.Parent and primaryPart.Parent then
			primaryPart:SetNetworkOwnershipAuto()
			log:debug("Successfully set auto network owner for vehicle {}", vehicleModel.Name)
		end
	end)
end

function funcs.handleAdminVehicleSpawn(player: Player, vehicleName: string, spawnCframe: CFrame)
	assert(typeof(vehicleName) == "string" and typeof(spawnCframe) == "CFrame")
	log:debug("Handling admin vehicle spawn event for player {}", player.Name)

	local character: Model? = player.Character
	assert(character)
	local currentTool = character:FindFirstChildOfClass("Tool")
	assert(currentTool and currentTool:HasTag(VehicleSystemConfig.VehicleSpawnerToolTag))

	local vehicle = VehicleSystemConfig.Folder:FindFirstChild(vehicleName) :: Model?
	assert(vehicle)

	SpawnerService.spawnVehicle(vehicle, spawnCframe)
end

function funcs.handleAdminVehicleDelete(player: Player, vehicle: Model)
	assert(typeof(vehicle) == "Instance")
	assert(vehicle:IsA("Model"))
	log:debug("Handling admin vehicle delete event for player {}", player.Name)

	local character: Model? = player.Character
	assert(character)
	local currentTool = character:FindFirstChildOfClass("Tool")
	assert(currentTool and currentTool:HasTag(VehicleSystemConfig.VehicleDeleterToolTag))

	assert(VehicleUtil.validateVehicle(vehicle))
	vehicle:Destroy()
end

function funcs.playSound(soundName: string, soundParent: Instance)
	local sound = soundParent:FindFirstChild(soundName) :: Sound?
	if sound then
		assert(sound:IsA("Sound"))
		sound:Play()
	end
end

-- setup the collision groups
PhysicsService:RegisterCollisionGroup("Vehicle")
PhysicsService:RegisterCollisionGroup("Wheel")
PhysicsService:CollisionGroupSetCollidable("Wheel", "Wheel", false)
PhysicsService:CollisionGroupSetCollidable("Wheel", "Vehicle", false)

VehicleRigService.DriverPromptTriggered = funcs.handleDriverPromptTriggered
VehicleRigService.PassengerPromptTriggered = funcs.handlePassengerPromptTriggered

setOwnershipRemote.OnServerEvent:Connect(funcs.handleSetOwnership)
adminDeleteRemote.OnServerEvent:Connect(funcs.handleAdminVehicleDelete)
adminSpawnRemote.OnServerEvent:Connect(funcs.handleAdminVehicleSpawn)

return module
