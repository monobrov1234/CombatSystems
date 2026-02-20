--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtil)
local PlayerGroupService = require(ServerScriptService.CombatSystemsServer.PlayerGroupService)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local PlayerTeamCheckUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.PlayerTeamCheckUtil)

-- IMPORTS INTERNAL
local VehicleRigService = require(script.Parent.RigService.VehicleRigService)

-- ROBLOX OBJECTS
-- C->S
local setOwnershipRemote = ReplicatedStorage.CombatSystemsShared.VehicleSystem.Events.ClientToServer.SetVehicleOwnership

-- FINALS
local log: Logger.SelfObject = Logger.new("VehicleSeatService")

-- INTERNAL FUNCTIONS
function funcs.handleDriverPromptTriggered(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt)
	if not funcs.checkVehicleAccessTool(player) then
		local seatConfig = vehicleInfo.VehicleConfig.SeatConfig
		if seatConfig.DriverGroupWhitelist and not PlayerGroupService.isInAnyWhitelistedGroup(player, seatConfig.DriverGroupWhitelist) then return end
		if seatConfig.DriverTeamWhitelist and not PlayerTeamCheckUtil.isInAnyWhitelistedTeam(player, seatConfig.DriverTeamWhitelist) then return end
	end

	funcs.handlePromptGeneric(player, vehicleInfo, prompt, vehicleInfo.DriverSeat)
end

function funcs.handlePassengerPromptTriggered(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt, seat: Seat)
	if not funcs.checkVehicleAccessTool(player) then
		local seatConfig = vehicleInfo.VehicleConfig.SeatConfig
		if seatConfig.PassengerGroupWhitelist and not PlayerGroupService.isInAnyWhitelistedGroup(player, seatConfig.PassengerGroupWhitelist) then return end
		if seatConfig.PassengerTeamWhitelist and not PlayerTeamCheckUtil.isInAnyWhitelistedTeam(player, seatConfig.PassengerTeamWhitelist) then return end
	end

	funcs.handlePromptGeneric(player, vehicleInfo, prompt, seat)
end

function funcs.handlePromptGeneric(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, prompt: ProximityPrompt, seat: Seat | VehicleSeat)
	local character: Model? = player.Character
	assert(character)
	if not funcs.trySitPlayer(player, seat) then return end

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

	cleaner:add(humanoid.Seated:Connect(function(active: boolean)
		if not active then resetPrompt() end
	end))

	cleaner:add(player.CharacterRemoving:Connect(function()
		resetPrompt()
	end))

	cleaner:add(Players.PlayerRemoving:Connect(function(playerRemoving: Player)
		if playerRemoving == player then resetPrompt() end
	end))

	funcs.handlePlayerSeated(player, vehicleInfo, seat)
end

function funcs.handlePlayerSeated(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, seat: Seat | VehicleSeat)
	if seat ~= vehicleInfo.DriverSeat then return end
	funcs.playSound("Enter", seat)

	local engineIdle = (vehicleInfo.EnginePart :: BasePart):FindFirstChild("EngineIdle") :: Sound?
	if engineIdle then engineIdle:Play() end

	local engineMove = (vehicleInfo.EnginePart :: BasePart):FindFirstChild("EngineMove") :: Sound?
	if not engineMove then return end

	local seatAsVehicleSeat = seat :: VehicleSeat
	local occupant = seatAsVehicleSeat.Occupant
	assert(occupant)

	local connection: RBXScriptConnection
	connection = seatAsVehicleSeat.Changed:Connect(function(property: string)
		if seatAsVehicleSeat.Occupant ~= occupant then
			engineMove:Stop()
			connection:Disconnect()
			return
		end

		if property ~= "Throttle" then return end

		if seatAsVehicleSeat.Throttle ~= 0 then
			engineMove:Play()
		else
			engineMove:Stop()
		end
	end)
end

function funcs.handleDismount(player: Player, vehicleInfo: VehicleUtil.VehicleInfo, seat: Seat | VehicleSeat)
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

	if seat ~= vehicleInfo.DriverSeat then return end
	funcs.playSound("Dismount", seat)

	local enginePart: BasePart? = vehicleInfo.EnginePart
	if enginePart then
		local engineIdle = enginePart:FindFirstChild("EngineIdle") :: Sound?
		if engineIdle then engineIdle:Stop() end
	end
end

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
	VehicleUtil.parseVehicleInfo(vehicleModel)

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

function funcs.trySitPlayer(player: Player, seat: BasePart): boolean
	assert(seat:IsA("Seat") or seat:IsA("VehicleSeat"))
	if seat.Occupant then return false end

	local character: Model? = player.Character
	if not character then return false end
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead or humanoid.SeatPart then return false end

	if seat:IsA("Seat") then
		seat:Sit(humanoid)
	elseif seat:IsA("VehicleSeat") then
		seat:Sit(humanoid)
	end

	return true
end

function funcs.checkVehicleAccessTool(player: Player): boolean
	local character: Model? = player.Character
	assert(character)
	local vehicleAccessTool: Tool? = character:FindFirstChildOfClass("Tool")
	return (vehicleAccessTool and vehicleAccessTool:HasTag(VehicleSystemConfig.VehicleAccessToolTag)) or false
end

function funcs.playSound(soundName: string, soundParent: Instance)
	local sound = soundParent:FindFirstChild(soundName) :: Sound?
	if not sound then return end
	assert(sound:IsA("Sound"))
	sound:Play()
end

-- SUBSCRIPTIONS
VehicleRigService.DriverPromptTriggered:connect(funcs.handleDriverPromptTriggered)
VehicleRigService.PassengerPromptTriggered:connect(funcs.handlePassengerPromptTriggered)
setOwnershipRemote.OnServerEvent:Connect(funcs.handleSetOwnership)

return module
