--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)

-- IMPORTS INTERNAL
local TurretStateService = require(script.Parent.TurretStateService)

-- ROBLOX OBJECTS
-- S->C
local setTurretStateRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ServerToClient.SetState
-- C->S
local switchShellsRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ClientToServer.SwitchShells
local switchGunRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ClientToServer.SwitchGun
-- SHARED
-- C->S: used to request mag reload from server; S->C used to tell client that reload has been finished and he can unlock his reload state
local reloadRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ClientToServer.ReloadTurret
local replicateReloadSoundRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ReplicateReloadSound

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretReloadService")

-- INTERNAL FUNCTIONS

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

	log:debug("Turret reloaded for player {}", player.Name)

	setTurretStateRemote:FireClient(player, stateInfo)
	reloadRemote:FireClient(player)
end

function funcs.handleReplicateReloadSound(player: Player, switch: boolean, usingMainGun: boolean)
	assert(typeof(switch) == "boolean" and typeof(usingMainGun) == "boolean")
	local turretInfo = TurretStateService.getPlayerCurrentTurret(player)
	assert(turretInfo)

	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicateReloadSoundRemote:FireClient(pl, turretInfo.PitchMotor.Part1, switch, usingMainGun)
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
replicateReloadSoundRemote.OnServerEvent:Connect(funcs.handleReplicateReloadSound)

return module
