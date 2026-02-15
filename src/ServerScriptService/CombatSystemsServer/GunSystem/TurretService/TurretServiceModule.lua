--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSystemConfig)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local TurretConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.TurretConfig)
local TurretConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.TurretConfigUtilModule)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)
local DestructibleObjectUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.DestructibleObject.DObjectUtilModule)
local PlayerGroupService = require(ServerScriptService.CombatSystemsServer.PlayerGroupServiceModule)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleanerModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

-- IMPORTS INTERNAL
local RigService = require(script.Parent.RigService.RigServiceModule)

-- ROBLOX OBJECTS
-- S->C
local setTurretStateRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ServerToClient.SetState
local replicateFireRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ServerToClient.ReplicateFire
-- C->S
local setTurretViewRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.SetTurretView
local reloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.ReloadTurret
local switchShellsRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.SwitchShells
local switchGunRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.SwitchGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ReplicateReload
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ReplicateState

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretService")

-- contains turret that player is currently controlling
type PlayerTurretInfo = {
	turretInfo: TurretUtil.TurretInfo,
	raycastBlacklist: { Instance }?,
}
local playerTurrets = {} :: { [Player]: PlayerTurretInfo? }
-- conttains own turret state for each turret on the map
local turretStateTable = {} :: { [Model]: TurretUtil.TurretStateInfo }

-- PUBLIC API
function module.getPlayerCurrentTurret(player: Player): TurretUtil.TurretInfo?
	local playerTurretInfo = playerTurrets[player]
	if playerTurretInfo then
		return playerTurretInfo.turretInfo
	else
		return nil
	end
end

-- INTERNAL API
-- used by TurretFireHandlerModule at MunitionService
-- validates that player is operating a turret and is permitted to fire from it in its current state
function module._handleTurretFire(rayInfo: RayInfo): RaycastParams
	local munitionName = rayInfo.MunitionConfig.MunitionName
	assert(rayInfo.Player)
	local player: Player = rayInfo.Player
	assert(player.Character)
	local playerTurretInfo: PlayerTurretInfo? = playerTurrets[player]
	assert(playerTurretInfo) -- should never happen, checked early in upper handler
	local turretInfo: TurretUtil.TurretInfo = playerTurretInfo.turretInfo
	local turretConfig: TurretConfigUtil.DefaultType = turretInfo.TurretConfig

	-- validation
	-- turretConfig must have that munition
	local stateInfo = funcs.getTurretStateInfo(turretInfo)
	if stateInfo.UsingMainGun then
		local ok = false
		for _, data in ipairs(turretConfig.GunConfig.AmmoTypes) do
			if data.name == munitionName then
				ok = true
				break
			end
		end
		assert(ok)
	else
		assert(turretConfig.GunConfig.CoaxConfig.AmmoType == munitionName)
	end

	funcs.fireTurret(stateInfo, munitionName)

	-- raycast params calculation
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	-- by default we ignore character, all projectiles, and turret model
	local filterDescendantsInstances = { turretInfo.TurretModel, player.Character, GunSystemConfig.ProjectileFolder } :: { Instance }
	if playerTurretInfo.raycastBlacklist then
		-- insert additional instances provided by SetTurretHandler
		for _, instance: Instance in ipairs(playerTurretInfo.raycastBlacklist) do
			table.insert(filterDescendantsInstances, instance)
		end
	end
	raycastParams.FilterDescendantsInstances = filterDescendantsInstances

	-- all ok, replicate fire
	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		local part = stateInfo.UsingMainGun and turretInfo.FiringPoint or turretInfo.FiringPointCoax
		replicateFireRemote:FireClient(pl, part, stateInfo.UsingMainGun)
	end

	return raycastParams
end

-- user by turret set hanlers
function module._setPlayerTurretView(player: Player, turretInfo: TurretUtil.TurretInfo?, raycastBlacklist: { Instance }?)
	if not turretInfo then
		playerTurrets[player] = nil
		log:debug("Player {} server turret info cleared", player.Name)
		return
	end

	playerTurrets[player] = {
		turretInfo = turretInfo,
		raycastBlacklist = raycastBlacklist,
	} :: PlayerTurretInfo

	local stateInfo = funcs.getTurretStateInfo(turretInfo)
	stateInfo.UsingMainGun = true -- by default erase coax state
	setTurretStateRemote:FireClient(player, stateInfo)

	log:debug("Player {} server turret info set to {}", player.Name, turretInfo.TurretModel.Name)
end

-- PRIVATE FUNCTIONS
-- handles sitting
-- RigService.SeatPromptTriggered
function funcs.handlePromptTriggered(player: Player, turretInfo: TurretUtil.TurretInfo, prompt: ProximityPrompt)
	local groupWhitelist: { number }? = turretInfo.TurretConfig.SeatConfig.GroupWhitelist

	local character = player.Character :: Model
	local vehicleAccessTool: Tool? = character:FindFirstChildOfClass("Tool")
	if not vehicleAccessTool or not vehicleAccessTool:HasTag(VehicleSystemConfig.VehicleAccessToolTag) then
		if groupWhitelist and not PlayerGroupService.isInAnyWhitelistedGroup(player, groupWhitelist) then return end
	end

	local seat: BasePart? = turretInfo.TurretSeat
	assert(seat) -- should never happen
	if funcs.trySitPlayer(player, seat) then
		prompt.Enabled = false
		local character = player.Character :: Model
		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

		local cleaner = ConnectionCleaner.new()
		local cleaned = false
		local function resetPrompt()
			if cleaned then return end
			cleaned = true
			prompt.Enabled = true
			cleaner:disconnectAll()
		end

		-- recheck memory leaks
		-- will re-enable prompt if player leaves the seat, guaranteed
		cleaner:add(humanoid.Seated:Connect(function(active)
			if not active then resetPrompt() end
		end))
		cleaner:add(player.CharacterRemoving:Connect(function()
			resetPrompt()
		end))
		cleaner:add(Players.PlayerRemoving:Connect(function(playerRemoving)
			if playerRemoving == player then resetPrompt() end
		end))
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

-- validates that turret clip has ammo and updates it
function funcs.fireTurret(stateInfo: TurretUtil.TurretStateInfo, munitionName: string)
	if stateInfo.UsingMainGun then
		assert(stateInfo.ClipSizeStorage[munitionName] > 0)
		stateInfo.ClipSizeStorage[munitionName] -= 1
	else
		assert(stateInfo.CoaxClipSize > 0)
		stateInfo.CoaxClipSize -= 1
	end
end

-- TODO: reload anticheat, capture time when player fired last munition
-- handles turret reload, and sends new turret state info
function funcs.handleReloadTurret(player: Player, isMain: boolean)
	local turretInfo = module.getPlayerCurrentTurret(player)
	assert(turretInfo)
	local stateInfo = funcs.getTurretStateInfo(turretInfo)

	local function refill(stored: number, clipSize: number, maxClipSize: number)
		local supplied = maxClipSize - clipSize
		local remaining = stored - supplied
		if remaining >= 0 then
			return maxClipSize, remaining
		else
			return clipSize + stored, 0
		end
	end

	if isMain then
		local selectedMunition = stateInfo.SelectedMunition
		local newClipSize, newStored =
			refill(stateInfo.MunitionStorage[selectedMunition], stateInfo.ClipSizeStorage[selectedMunition], turretInfo.TurretConfig.GunConfig.ClipSize)
		stateInfo.ClipSizeStorage[selectedMunition] = newClipSize
		stateInfo.MunitionStorage[selectedMunition] = newStored
	else
		local newClipSize, newStored = refill(stateInfo.CoaxAmmoSize, stateInfo.CoaxClipSize, turretInfo.TurretConfig.GunConfig.CoaxConfig.ClipSize)
		stateInfo.CoaxClipSize = newClipSize
		stateInfo.CoaxAmmoSize = newStored
	end

	setTurretStateRemote:FireClient(player, stateInfo)
end

function funcs.handleSwitchShells(player: Player)
	local turretInfo = module.getPlayerCurrentTurret(player)
	assert(turretInfo)
	local stateInfo = funcs.getTurretStateInfo(turretInfo)
	assert(#turretInfo.TurretConfig.GunConfig.AmmoTypes > 1)

	local currIndex: number? = nil
	for i, data in ipairs(turretInfo.TurretConfig.GunConfig.AmmoTypes) do
		if data.name == stateInfo.SelectedMunition then currIndex = i end
	end
	assert(currIndex) -- should never happen
	currIndex = currIndex :: number

	currIndex += 1
	if currIndex > #turretInfo.TurretConfig.GunConfig.AmmoTypes then currIndex = 1 end

	-- switch shell
	stateInfo.SelectedMunition = turretInfo.TurretConfig.GunConfig.AmmoTypes[currIndex].name

	-- reload switched shell immediately
	funcs.handleReloadTurret(player, true)
end

function funcs.handleSwitchGun(player: Player, usingMainGun: boolean)
	local turretInfo = module.getPlayerCurrentTurret(player)
	assert(turretInfo)
	local stateInfo = funcs.getTurretStateInfo(turretInfo)
	stateInfo.UsingMainGun = usingMainGun
	setTurretStateRemote:FireClient(player, stateInfo)
end

function funcs.handleReplicateReload(player: Player, switch: boolean, usingMainGun: boolean)
	assert(typeof(switch) == "boolean" and typeof(usingMainGun) == "boolean")
	local turretInfo = module.getPlayerCurrentTurret(player)
	assert(turretInfo)

	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicateReloadRemote:FireClient(pl, turretInfo.PitchMotor.Part1, switch, usingMainGun)
	end
end

-- handles turret replication from client to all clients, server knows nothing - only validates turret state
function funcs.handleReplicateTurretState(player: Player, yawRotationC0: Vector3, pitchRotationC0: Vector3)
	assert(typeof(yawRotationC0) == "Vector3" and typeof(pitchRotationC0) == "Vector3")
	local turretInfo = module.getPlayerCurrentTurret(player)
	if not turretInfo or not turretInfo.TurretModel.Parent then return end --assert(turretInfo) will flood console
	turretInfo.YawMotor.C0 = CFrame.new(turretInfo.YawMotor.C0.Position) * CFrame.fromOrientation(yawRotationC0.X, yawRotationC0.Y, yawRotationC0.Z)
	turretInfo.PitchMotor.C0 = CFrame.new(turretInfo.PitchMotor.C0.Position) * CFrame.fromOrientation(pitchRotationC0.X, pitchRotationC0.Y, pitchRotationC0.Z)
end

-- returns turret stored data from global storage, if nothing found - creates and adds new one
function funcs.getTurretStateInfo(turretInfo: TurretUtil.TurretInfo): TurretUtil.TurretStateInfo
	local turretModel: Model = turretInfo.TurretModel
	local entry: TurretUtil.TurretStateInfo? = turretStateTable[turretModel]
	if not entry then
		local gunConfig = turretInfo.TurretConfig.GunConfig

		local clipSizeStorage = {}
		local munitionStorage = {}
		for _, data in ipairs(gunConfig.AmmoTypes) do
			clipSizeStorage[data.name] = gunConfig.ClipSize
			munitionStorage[data.name] = data.stored
		end

		entry = {
			SelectedMunition = gunConfig.AmmoTypes[1].name,
			ClipSizeStorage = clipSizeStorage,
			MunitionStorage = munitionStorage,
			UsingMainGun = false,
			CoaxClipSize = gunConfig.CoaxConfig.ClipSize,
			CoaxAmmoSize = gunConfig.CoaxConfig.AmmoSize,
		}
		turretStateTable[turretModel] = entry

		-- recheck memory leaks
		-- auto remove from global storage if the turret is destroyed
		turretModel.Destroying:Once(function()
			log:debug("Turret {} destroyed, removing its state", turretModel.Name)
			turretStateTable[turretModel] = nil
		end)
	end

	return entry :: TurretUtil.TurretStateInfo
end

-- playerTurrets table clean logic
Players.PlayerRemoving:Connect(function(player: Player)
	playerTurrets[player] = nil
end)

reloadRemote.OnServerEvent:Connect(funcs.handleReloadTurret)
switchShellsRemote.OnServerEvent:Connect(funcs.handleSwitchShells)
switchGunRemote.OnServerEvent:Connect(funcs.handleSwitchGun)
replicateReloadRemote.OnServerEvent:Connect(funcs.handleReplicateReload)
replicationRemote.OnServerEvent:Connect(funcs.handleReplicateTurretState)

RigService.SeatPromptTriggered = funcs.handlePromptTriggered

return module
