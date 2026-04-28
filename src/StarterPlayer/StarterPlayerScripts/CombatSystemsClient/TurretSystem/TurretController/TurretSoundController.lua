--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)

-- ROBLOX OBJECTS
-- S->C
local replicateFireSoundRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ServerToClient.ReplicateFireSound -- replicated client side in TurretReloadController, then processed in TurretReloadService
-- SHARED
local replicateReloadSoundRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ReplicateReloadSound -- replicated server side in TurretFireService

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretSoundController")

-- PUBLIC API
function module.play(soundName: string, soundParent: Instance)
	funcs.playSound(soundName, soundParent)
end

-- INTERNAL FUNCTIONS
function funcs.handleReplicateFire(part: BasePart, usingMainGun: boolean)
	log:debug("Handling fire sound replication from {}", part.Position)
	funcs.playSound(usingMainGun and "Fire" or "FireCoax", part)
end

function funcs.handleReplicateReload(part: BasePart, switch: boolean, usingMainGun: boolean)
	if switch then
		log:debug("Handling munition switch sound replication from {}", part.Position)
		funcs.playSound("Switch", part)
	else
		log:debug("Handling reload sound replication from {}", part.Position)
		funcs.playSound(usingMainGun and "Reload" or "ReloadCoax", part)
	end
end

function funcs.playSound(soundName: string, soundParent: Instance)
	local sound = soundParent:FindFirstChild(soundName) :: Sound?
	if sound then
		assert(sound:IsA("Sound"))
		sound:Play()
	end
end

-- SUBSCRIPTIONS
replicateFireSoundRemote.OnClientEvent:Connect(funcs.handleReplicateFire)
replicateReloadSoundRemote.OnClientEvent:Connect(funcs.handleReplicateReload)

return module
