--!strict

--[[
	BackpackController (Client-Side)
	
	This module manages client-side logic for handling guns in the player's inventory (Backpack).
	It is responsible for:
	- Backpack actions such as: adding to backpack, removing from backpack
	- Managing gun animations, initializing and destroying them on backpack add/remove
	- Managing gun server state
]]

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local SignalModule = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- ROBLOX OBJECTS
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator

-- REMOTES
-- S->C
local setStateRemote = ReplicatedStorage.CombatSystemsShared.GunSystem.Events.Core.ServerToClient.SetGunState

-- FINALS
local log: Logger.SelfObject = Logger.new("GunBackpackController")

export type SharedGunState = { -- this will be changed by server sometimes
	MagSize: number,
	AmmoSize: number,
}
export type GunState = { -- global gun state object, containing fields that server won't update and server updatable SharedState field
	SharedState: SharedGunState,
	LastShootTime: number,
	Dirty: boolean, -- used to block reloads until server updates shared state
}
local stateTable: { [Tool]: GunState } = {} -- each gun have its GunState to remember mag size and other stuff
local loadedAnims: { [Tool]: { [Animation]: AnimationTrack } } = {} -- when new gun tool is added to backpack, its animations are loaded as tracks and put here

-- STATE
local equippedGun: GunUtil.GunInfo?

-- INTERNAL EVENTS
module.GunEquipped = SignalModule.new() -- (gunInfo: GunUtil.GunInfo)
module.GunUnequipped = SignalModule.new() -- (gunInfo: GunUtil.GunInfo)
module.SetGunState = SignalModule.new() -- (gunTool: Tool, newState: SharedGunState)

-- PUBLIC API
function module.getStateFor(gunTool: Tool): GunState?
	return stateTable[gunTool]
end

-- Resolves a preloaded animation track for the given gun tool and animation instance.
function module.resolveAnim(gunTool: Tool, anim: Animation): AnimationTrack?
	local anims = module.getLoadedAnimsFor(gunTool)
	if anims then
		return anims[anim]
	else return nil end
end

function module.getLoadedAnimsFor(gunTool: Tool): { [Animation]: AnimationTrack }?
	return loadedAnims[gunTool]
end

function module.getEquippedGun(): GunUtil.GunInfo?
	return equippedGun
end

-- INTERNAL FUNCTIONS

-- Called when a new gun tool is added to the player's backpack.
-- Registers the gun, loads animations, and sets up initial state.
function funcs.handleGunAdded(gunTool: Tool)
	if not gunTool:IsA("Tool") then return end
	if not GunUtil.validateGun(gunTool) then return end
	local state = stateTable[gunTool]
	if state then return end -- gun already registered

	local gunInfo: GunUtil.GunInfo = GunUtil.parseGunInfo(gunTool)
	gunTool.AncestryChanged:Connect(function(child: Instance, newParent: Instance?)
		if child ~= gunTool then return end
		if newParent == player.Character then
			-- gun was equipped
			module.GunEquipped:fire(gunInfo)
			equippedGun = gunInfo
		else
			if equippedGun and equippedGun.Tool == gunTool then
				-- gun was unequipped
				module.GunUnequipped:fire(gunInfo)
				stateTable[gunTool].Dirty = false -- to prevent desync where dirty will be true forever
				equippedGun = nil
			end

			if newParent ~= player.Backpack then
				-- gun was removed from inventory
				funcs.handleGunRemoved(gunInfo)
			end
		end
	end)

	-- load all gun animations when it was first added to the inventory
	loadedAnims[gunTool] = {}
	for _, anim: Animation in ipairs(gunInfo.Config.DecorConfig.AnimationsFolder:GetChildren()) do
		local track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action
		loadedAnims[gunTool][anim] = track
	end

	stateTable[gunTool] = {
		SharedState = {
			MagSize = gunInfo.Config.GunConfig.MagSize,
			AmmoSize = gunInfo.Config.GunConfig.AmmoSize,
		},
		LastShootTime = 0,
		Dirty = false,
	}

	log:debug("Client gun added to inventory: {}", gunTool.Name)
end

-- Cleans up resources when a gun is removed from the backpack.
function funcs.handleGunRemoved(gunInfo: GunUtil.GunInfo)
	-- clean up all animation tracks
	for anim: Animation, track: AnimationTrack in pairs(loadedAnims[gunInfo.Tool]) do
		track:Destroy()
	end
	loadedAnims[gunInfo.Tool] = nil
	stateTable[gunInfo.Tool] = nil
	log:debug("Client gun removed from inventory: {}", gunInfo.Tool.Name)
end

-- Updates local gun state from server (e.g., after reload).
function funcs.handleSetGunState(gunTool: Tool, newState: SharedGunState)
	local state = stateTable[gunTool]
	if state then
		state.SharedState = newState
		state.Dirty = false
		module.SetGunState:fire(gunTool, newState)
	end
end

-- HOOKS

-- Hooks up to the player's backpack to monitor gun additions.
function funcs.hookBackpack(backpack: Backpack)
	for _, tool: Instance in ipairs(backpack:GetChildren()) do
		if not tool:IsA("Tool") then continue end
		funcs.handleGunAdded(tool)
	end

	backpack.ChildAdded:Connect(function(child: Instance)
		if not child:IsA("Tool") then return end
		funcs.handleGunAdded(child)
	end)
end
funcs.hookBackpack(player.Backpack)

-- Updates character references and re-hooks backpack on respawn.
function funcs.updateCharacter(newCharacter: Model)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	funcs.hookBackpack(player.Backpack)
end
player.CharacterAdded:Connect(funcs.updateCharacter)

-- SUBSCRIPTIONS
setStateRemote.OnClientEvent:Connect(funcs.handleSetGunState)

return module