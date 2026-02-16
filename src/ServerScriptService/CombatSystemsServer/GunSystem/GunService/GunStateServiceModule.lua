--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtilModule)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)

-- FINALS
local log: Logger.SelfObject = Logger.new("GunStateService")

export type SharedGunState = {
	MagSize: number,
	AmmoSize: number,
}
export type GunState = {
	SharedState: SharedGunState,
	LastShootTime: number,
}
local stateTable: { [Tool]: GunState } = {}

-- PUBLIC EVENTS
module.GunEquipped = Signal.new() -- (player: Player, gunInfo: GunUtil.GunInfo)
module.GunUnequipped = Signal.new() -- (player: Player, gunInfo: GunUtil.GunInfo)

-- PUBLIC API
function module.getGunState(gunTool: Tool): GunState?
    return stateTable[gunTool]
end

-- INTERNAL FUNCTIONS
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
			module.GunEquipped:fire(player, gunInfo)
		else
			if equippedTool == gunTool then
				equippedTool = nil
				module.GunUnequipped:fire(player, gunInfo)
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

return module
