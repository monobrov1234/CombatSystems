local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local MunitionService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.MunitionService)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)

-- IMPORTS INTERNAL
local GunStateService = require(script.Parent.GunStateService)

-- ROBLOX OBJECTS
-- S->C
local replicateFireRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.Core.ServerToClient.ReplicateFireGun

-- handles gun fire after validation
function funcs.handleGunFire(rayInfo: RayTypeService.RayInfo)
	local player: Player? = rayInfo.Player
	if not player then return end
	local character: Model? = player.Character
	if not character then return end

	local tool: Tool? = character:FindFirstChildOfClass("Tool")
	if not tool or not GunUtil.validateGun(tool) then return end
	
	local state = GunStateService.getGunState(tool)
	assert(state)
	local gunInfo = GunUtil.parseGunInfo(tool)

	-- fire
	state.SharedState.MagSize = math.max(0, state.SharedState.MagSize - 1)
	state.LastShootTime = os.clock()

	-- replicate fire sound
	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == rayInfo.Player then continue end
		replicateFireRemote:FireClient(pl, gunInfo.FiringPoint)
	end
end

MunitionService.FireMunition:connect(funcs.handleGunFire)

return module
