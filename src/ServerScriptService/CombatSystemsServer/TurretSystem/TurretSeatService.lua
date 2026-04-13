--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGroupService = require(ServerScriptService.CombatSystemsServer.PlayerGroupService)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.VehicleSystemConfig)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local PlayerTeamCheckUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.PlayerTeamCheckUtil)

-- IMPORTS INTERNAL
local RigService = require(script.Parent.RigService.TurretRigService)

-- handles prompt interaction
function funcs.handleSeatPromptTriggered(player: Player, turretInfo: TurretUtil.TurretInfo, prompt: ProximityPrompt)
	local character = player.Character :: Model
	local vehicleAccessTool: Tool? = character:FindFirstChildOfClass("Tool")
	if not vehicleAccessTool or not vehicleAccessTool:HasTag(VehicleSystemConfig.VehicleAccessToolTag) then
		local seatConfig = turretInfo.TurretConfig.SeatConfig
		if seatConfig.GroupWhitelist and not PlayerGroupService.isInAnyWhitelistedGroup(player, seatConfig.GroupWhitelist) then return end
		if seatConfig.TeamWhitelist and not PlayerTeamCheckUtil.isInAnyWhitelistedTeam(player, seatConfig.TeamWhitelist) then return end
	end

	local seat: BasePart? = turretInfo.TurretSeat
	assert(seat) -- should never happen
	if funcs.trySitPlayer(player, seat) then
		prompt.Enabled = false
		local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
		assert(humanoid)

		local cleaner = ConnectionCleaner.new()
		local cleaned = false
		local function resetPrompt()
			if cleaned then return end
			cleaned = true
			prompt.Enabled = true
			cleaner:disconnectAll()
			funcs.handleDismount(player, seat)
		end

		-- recheck memory leaks
		-- will re-enable prompt if player leaves the seat, guaranteed
		cleaner:add(humanoid.Seated:Connect(function(active)
			if not active then resetPrompt() end
		end))
		cleaner:add(player.CharacterRemoving:Connect(function()
			resetPrompt()
		end))
		cleaner:add(Players.PlayerRemoving:Connect(function(playerRemoving: Player)
			if playerRemoving == player then resetPrompt() end
		end))
	end
end

function funcs.handleDismount(player: Player, seat: BasePart)
	local dismountPart = seat:FindFirstChild("DismountPart") :: BasePart?
	if dismountPart and dismountPart:IsA("BasePart") then
		local character: Model? = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if humanoidRootPart and humanoidRootPart:IsA("BasePart") then 
				humanoidRootPart:PivotTo(dismountPart.CFrame) 
			end
		end
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

RigService.SeatPromptTriggered:connect(funcs.handleSeatPromptTriggered)
return module