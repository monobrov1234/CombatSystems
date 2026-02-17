--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MunitionService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionServiceModule)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

-- IMPORTS INTERNAL
local TurretStateService = require(script.Parent.TurretStateServiceModule)

-- ROBLOX OBJECTS
-- S->C
local setTurretStateRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ServerToClient.SetState
-- C->S
local reloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.ReloadTurret
local switchShellsRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.SwitchShells
local switchGunRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ClientToServer.SwitchGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ReplicateReload
local replicationRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.TurretService.ReplicateState

-- FINALS
local _log: Logger.SelfObject = Logger.new("TurretService")

-- INTERNAL FUNCTIONS

-- handles turret replication from the client to othe clients, server knows nothing - only validates turret state
function funcs.handleReplicateTurretState(player: Player, yawRotationC0: Vector3, pitchRotationC0: Vector3)
	assert(typeof(yawRotationC0) == "Vector3" and typeof(pitchRotationC0) == "Vector3")
	local turretInfo = TurretStateService.getPlayerCurrentTurret(player)
	if not turretInfo or not turretInfo.TurretModel.Parent then return end --assert(turretInfo) will flood console
	turretInfo.YawMotor.C0 = CFrame.new(turretInfo.YawMotor.C0.Position) * CFrame.fromOrientation(yawRotationC0.X, yawRotationC0.Y, yawRotationC0.Z)
	turretInfo.PitchMotor.C0 = CFrame.new(turretInfo.PitchMotor.C0.Position) * CFrame.fromOrientation(pitchRotationC0.X, pitchRotationC0.Y, pitchRotationC0.Z)
end

-- handles turret munition fire after validation
function funcs.handleTurretFire(rayInfo: MunitionRayInfo.Type)
	local player: Player? = rayInfo.Player
	if not player then return end
	local character: Model? = player.Character
	if not character then return end

	local turretInfo: TurretUtil.TurretInfo? = TurretStateService.getPlayerCurrentTurret(player)
	if not turretInfo then return end
	local stateInfo = TurretStateService.getTurretState(turretInfo)
	assert(stateInfo)

	local munitionName = rayInfo.MunitionConfig.MunitionName
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
	local turretInfo = TurretStateService.getPlayerCurrentTurret(player)
	assert(turretInfo)
	local stateInfo = TurretStateService.getTurretState(turretInfo)
	assert(stateInfo)

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

-- handles reload replication (reload sound)
function funcs.handleReplicateReload(player: Player, switch: boolean, usingMainGun: boolean)
	assert(typeof(switch) == "boolean" and typeof(usingMainGun) == "boolean")
	local turretInfo = TurretStateService.getPlayerCurrentTurret(player)
	assert(turretInfo)

	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicateReloadRemote:FireClient(pl, turretInfo.PitchMotor.Part1, switch, usingMainGun)
	end
end

function funcs.handleSwitchShells(player: Player)
	local turretInfo = TurretStateService.getPlayerCurrentTurret(player)
	assert(turretInfo)
	local stateInfo = TurretStateService.getTurretState(turretInfo)
	assert(stateInfo)
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
	local turretInfo = TurretStateService.getPlayerCurrentTurret(player)
	assert(turretInfo)
	local stateInfo = TurretStateService.getTurretState(turretInfo)
	assert(stateInfo)
	stateInfo.UsingMainGun = usingMainGun
	setTurretStateRemote:FireClient(player, stateInfo)
end

-- SUBSCRIPTIONS
reloadRemote.OnServerEvent:Connect(funcs.handleReloadTurret)
switchShellsRemote.OnServerEvent:Connect(funcs.handleSwitchShells)
switchGunRemote.OnServerEvent:Connect(funcs.handleSwitchGun)
replicateReloadRemote.OnServerEvent:Connect(funcs.handleReplicateReload)
replicationRemote.OnServerEvent:Connect(funcs.handleReplicateTurretState)

-- custom
MunitionService.FireMunition:connect(funcs.handleTurretFire)

return module
