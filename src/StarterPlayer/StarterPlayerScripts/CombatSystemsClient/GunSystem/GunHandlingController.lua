--!strict

--[[
	HandlingController (Client-Side)
	
	This module handles client-side gun handling (equipping and unequipping)
    It is responsible for playing idle animations, initializing and destroying necessary modules required to perform firing, reloading, etc.
]]

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local SignalModule = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- IMPORTS INTERNAL
local BackpackController = require(script.Parent.BackpackController)

-- FINALS
local log: Logger.SelfObject = Logger.new("GunHandlingController")

-- STATE
local toolAnim: Motor6D?

-- Handles gun equipping: Sets up Motor6D for animation, raycast params, GUI, recoil, cursor.
function funcs.handleGunEquipped(gunInfo: GunUtil.GunInfo)
	local character: Model? = player.Character
	if not character then return end
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local torso = (humanoid.RigType == Enum.HumanoidRigType.R6
		and character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")) :: BasePart?
	if torso then
		toolAnim = Instance.new("Motor6D")
		assert(toolAnim)
		toolAnim.Name = "toolAnim"
		toolAnim.Part0 = torso
		toolAnim.Part1 = gunInfo.AnimPart
		toolAnim.Parent = torso

		-- i do not want gun model to be visible in unanimated position for a moment, hide the gun
		toolAnim.C0 = CFrame.new(0, 500, 0)
		RunService.Heartbeat:Once(function()
			-- show the gun when starting animations is correctly showing
			toolAnim.C0 = CFrame.new(0, 0, 0)
		end)
	else 
		log:warn("Character torso not found!")
	end
end

-- Handles gun unequipping: Stops animations, cleans up connections, GUI, recoil, etc.
function funcs.handleGunUnequipped(gunInfo: GunUtil.GunInfo)
	-- stop all running animations
	local loadedAnims = BackpackController.getLoadedAnimsFor(gunInfo.Tool)
	assert(loadedAnims) -- should not happen
	for _: Animation, track: AnimationTrack in pairs(loadedAnims) do
        if track.IsPlaying then
        	track:Stop()
        end
	end

	-- remove animation motor6d
	if toolAnim then toolAnim:Destroy() end
end

-- SUBSCRIPTIONS
BackpackController.GunEquipped:connect(funcs.handleGunEquipped, SignalModule.Priority.HIGH)
BackpackController.GunUnequipped:connect(funcs.handleGunUnequipped, SignalModule.Priority.HIGH)

return module