local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunSystemConfig)
local GunConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.GunConfigUtilModule)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtilModule)

type RayInfo = typeof(require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.SharedEntities.RayInfo.MunitionRayInfo))

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

type SharedGunState = {
	MagSize: number,
	AmmoSize: number,
}
type GunState = {
	SharedState: SharedGunState,
	LastShootTime: number,
}
local stateTable: { [Tool]: GunState } = {}

function funcs.handleGunAdded(player: Player, gunTool: Tool)
	if not gunTool:IsA("Tool") or not GunUtil.validateGun(gunTool) then return end -- this is not a gun
	if stateTable[gunTool] then return end -- gun already registered

	local gunInfo = GunUtil.parseGunInfo(gunTool)

	-- hook gun
	local equippedTool: Tool?
	gunTool.AncestryChanged:Connect(function(child: Instance, newParent: Instance?)
		if child ~= gunTool then return end
		if newParent == player.Character then
			-- gun was equipped
			equippedTool = gunTool
			funcs.handleGunEquipped(player, gunInfo)
		else
			if equippedTool == gunTool then
				equippedTool = nil
				funcs.handleGunUnequipped(player, gunInfo)
			end

			if newParent ~= player.Backpack then
				-- gun was removed from inventory
				stateTable[gunTool] = nil
				log:debug("Server gun removed: {}", gunTool.Name)
			end
		end
	end)

	stateTable[gunTool] = {
		SharedState = {
			MagSize = gunInfo.Config.GunConfig.MagSize,
			AmmoSize = gunInfo.Config.GunConfig.AmmoSize,
		},
		LastShootTime = 0,
	}

	log:debug("Server gun added: {}", gunTool.Name)
end

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

-- called from munitionservice to handle and validate fire event from player
function module.handleGunFire(rayInfo: RayInfo, gunTool: Tool): RaycastParams
	local state = stateTable[gunTool]
	assert(state)
	assert(state.SharedState.MagSize > 0)

	local gunInfo = GunUtil.parseGunInfo(gunTool)
	assert(gunInfo.Config.GunConfig.AmmoType == rayInfo.MunitionConfig.MunitionName)

	-- player in correct state, fire gun
	state.SharedState.MagSize = math.max(0, state.SharedState.MagSize - 1)
	state.LastShootTime = os.clock()

	-- replicate fire sound
	for _, pl: Player in ipairs(Players:GetPlayers()) do
		if pl == rayInfo.Player then continue end
		replicateFireRemote:FireClient(pl, gunInfo.FiringPoint)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	assert(rayInfo.Player)
	raycastParams.FilterDescendantsInstances = { rayInfo.Player.Character, gunTool, GunSystemConfig.ProjectileFolder }
	return raycastParams
end

-- TODO: validate last shoot time
function funcs.handleGunReload(player: Player, gunTool: Tool)
	local character = player.Character
	if not character then return end
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if equippedTool ~= gunTool then return end

	local config = GunConfigUtil.getConfig(gunTool.Name)
	assert(config)
	local state = stateTable[gunTool]
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

function funcs.hookPlayerBackpack(player: Player)
	for _, tool: Instance in ipairs(player.Backpack:GetChildren()) do
		if not tool:IsA("Tool") then continue end
		funcs.handleGunAdded(player, tool)
	end

	player.Backpack.ChildAdded:Connect(function(child: Instance)
		if not child:IsA("Tool") then return end
		funcs.handleGunAdded(player, child)
	end)

	log:debug("Player backpack hooked: ", player.Name)
end

function funcs.hookPlayer(player: Player)
	funcs.hookPlayerBackpack(player)
	player.CharacterAdded:Connect(function()
		funcs.hookPlayerBackpack(player)
	end)

	log:debug("Player hooked: ", player.Name)
end

for _, player in ipairs(Players:GetPlayers()) do
	funcs.hookPlayer(player)
end
Players.PlayerAdded:Connect(funcs.hookPlayer)

reloadRemote.OnServerEvent:Connect(funcs.handleGunReload)
replicateReloadRemote.OnServerEvent:Connect(funcs.handleReplicateReload)

return module
