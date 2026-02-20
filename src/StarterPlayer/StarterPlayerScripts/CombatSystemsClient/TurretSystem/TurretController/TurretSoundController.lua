--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ROBLOX OBJECTS
-- S->C
local replicateFireRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ServerToClient.ReplicateFire
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.TurretSystem.Events.Core.ReplicateReload

-- PUBLIC API
function module.play(soundName: string, soundParent: Instance)
	funcs.playSound(soundName, soundParent)
end

-- INTERNAL FUNCTIONS
function funcs.handleReplicateFire(part: BasePart, usingMainGun: boolean)
	funcs.playSound(usingMainGun and "Fire" or "FireCoax", part)
end

function funcs.handleReplicateReload(part: BasePart, switch: boolean, usingMainGun: boolean)
	if switch then
		funcs.playSound("Switch", part)
	else
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
replicateFireRemote.OnClientEvent:Connect(funcs.handleReplicateFire)
replicateReloadRemote.OnClientEvent:Connect(funcs.handleReplicateReload)

return module
