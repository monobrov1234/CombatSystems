local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionService = require(ServerScriptService.CombatSystemsServer.GunSystem.MunitionService.MunitionServiceModule)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local GunConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.GunConfigUtilModule)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtilModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

-- IMPORTS INTERNAL
local GunStateService = require(script.Parent.GunStateServiceModule)

-- ROBLOX OBJECTS
-- S->C
local setStateRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ServerToClient.SetGunState
local replicateFireRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ServerToClient.ReplicateFireGun
-- C->S
local reloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ClientToServer.ReloadGun
-- SHARED
local replicateReloadRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.GunService.ReplicateReloadGun

-- FINALS
local log: Logger.SelfObject = Logger.new("GunService")

function funcs.handleGunEquipped(player: Player, gunInfo: GunUtil.GunInfo)
	local character = player.Character
	if not character then return end
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator: Animator? = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local torso = (humanoid.RigType == Enum.HumanoidRigType.R6
		and character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")) :: BasePart?
	if not torso then return end

	local animPart = gunInfo.Tool:FindFirstChild("AnimPart") :: BasePart
	local toolAnim = Instance.new("Motor6D")
	toolAnim.Name = "toolAnim"
	toolAnim.Part0 = torso
	toolAnim.Part1 = animPart
	toolAnim.Parent = torso

	log:debug("Server gun equipped: {}", gunInfo.Tool.Name)
end

function funcs.handleGunUnequipped(player: Player, gunInfo: GunUtil.GunInfo)
	local character = player.Character
	if not character then return end
	local humanoid: Humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local torso = humanoid.RigType == Enum.HumanoidRigType.R6 and character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not torso then return end

	local toolAnim = torso:FindFirstChild("toolAnim")
	if not toolAnim then return end
	toolAnim:Destroy()

	log:debug("Server gun unequipped: {}", gunInfo.Tool.Name)
end

-- handles gun fire after validation
function funcs.handleGunFire(rayInfo: RayInfo)
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

-- TODO: validate last shoot time
function funcs.handleGunReload(player: Player, gunTool: Tool)
	local character = player.Character
	if not character then return end
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool ~= gunTool then return end

	local config = GunConfigUtil.getConfig(gunTool.Name)
	assert(config)
	local state = GunStateService.getGunState(gunTool)
	assert(state)

	local ammoSize = state.SharedState.AmmoSize
	local magSize = state.SharedState.MagSize
	local neededAmmo = config.GunConfig.MagSize - magSize
	if ammoSize >= neededAmmo then
		state.SharedState.MagSize = config.GunConfig.MagSize
		state.SharedState.AmmoSize -= neededAmmo
	else
		state.SharedState.MagSize += ammoSize
		state.SharedState.AmmoSize = 0
	end

	setStateRemote:FireClient(player, gunTool, state.SharedState)
end

function funcs.handleReplicateReload(player: Player, gunTool: Tool)
	local character = player.Character
	if not character then return end
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool ~= gunTool then return end

	local gunInfo = GunUtil.parseGunInfo(gunTool)
	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == player then continue end
		replicateReloadRemote:FireClient(pl, gunInfo.AnimPart)
	end
end

reloadRemote.OnServerEvent:Connect(funcs.handleGunReload)
replicateReloadRemote.OnServerEvent:Connect(funcs.handleReplicateReload)

-- custom
GunStateService.GunEquipped:connect(funcs.handleGunEquipped)
GunStateService.GunUnequipped:connect(funcs.handleGunUnequipped)
MunitionService.FireMunition:connect(funcs.handleGunFire)

return module
