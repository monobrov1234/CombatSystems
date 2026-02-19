local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TurretStateService = require(ServerScriptService.CombatSystemsServer.TurretSystem.TurretStateService)
local VehicleUtil = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Modules.VehicleUtilModule)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)

function funcs.handleHumanoidSeated(player: Player, seat: BasePart)
	if not seat then
		TurretStateService.setPlayerTurretView(player, nil, nil)
		return
	end

	if TurretStateService.getPlayerCurrentTurret(player) then return end

	-- find player current vehicle
	local vehicleInfo: VehicleUtil.VehicleInfo? = VehicleUtil.findPlayerCurrentVehicle(player)
	if not vehicleInfo then return end

	-- find target turret model
	local turretModel: Model
	if seat == vehicleInfo.DriverSeat then
		if not vehicleInfo.VehicleConfig.HasDriverTurret then return end -- player is just driver, no turret
		-- player is operating driver turret
		-- find driver gunner turret (turret without any seats)
		local turrets: { Model } = TurretUtil.findDescendantTurrets(vehicleInfo.VehicleModel)
		for _, turret: Model in ipairs(turrets) do
			if TurretUtil.findTurretSeat(turret) then continue end
			turretModel = turret
			break
		end
	elseif TurretUtil.validateTurret(seat.Parent :: Model) then
		-- player is operating mounted turret with a seat
		turretModel = seat.Parent :: Model
	else
		-- player is vehicle passenger, return
		return
	end

	assert(turretModel) -- should not happen

	local turretInfo: TurretUtil.TurretInfo = TurretUtil.parseTurretInfo(turretModel)
	TurretStateService.setPlayerTurretView(player, turretInfo, { vehicleInfo.VehicleModel })
end

local function hookSeated(player: Player)
	local function hookCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Seated:Connect(function(active: boolean, seatPart: BasePart)
			funcs.handleHumanoidSeated(player, seatPart)
		end)
	end

	if player.Character then hookCharacter(player.Character) end
	player.CharacterAdded:Connect(hookCharacter)
end

for _, player: Player in ipairs(Players:GetPlayers()) do
	hookSeated(player)
end

Players.PlayerAdded:Connect(function(player: Player)
	hookSeated(player)
end)
