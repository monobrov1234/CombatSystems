--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.GunSystemConfig)

-- IMPORTS INTERNAL
local BackpackController = require(script.Parent.BackpackController)
local GunFireController = require(script.Parent.GunFireController)
local GunReloadController = require(script.Parent.GunReloadController)
local MovementController = require(PlayerScripts.CombatSystemsClient.MovementSystem.MovementController)

-- ROBLOX OBJECTS
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- STATE
local gunInfo: GunUtil.GunInfo?
local idle = false
local sprintHold = false
local patrol = false

-- INTERNAL FUNCTIONS
function funcs.handleGunEquipped(newGunInfo: GunUtil.GunInfo)
	gunInfo = newGunInfo
	if MovementController.isSprinting() and humanoid.MoveDirection.Magnitude ~= 0 then
		funcs.setSprintHold(true)
	else
		funcs.setIdle(true)
	end
end

function funcs.handleGunUnequipped()
	idle = false
	sprintHold = false
	patrol = false
	gunInfo = nil
end

function funcs.handleInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not gunInfo then return end

	if input.KeyCode == GunSystemConfig.KeyBindings.PatrolKey then 
		if MovementController.isSprinting() and humanoid.MoveDirection.Magnitude ~= 0 then return end
		if GunFireController.isFiring() then return end
		if GunReloadController.isReloading() then return end
	
		if patrol then
			funcs.setPatrol(false)
		else
			funcs.setPatrol(true)
		end
	end
end

function funcs.handleSprintStateChange(oldState: boolean, newState: boolean)
	if not gunInfo then return end
	funcs.setPatrol(false)

	if not newState then
		funcs.setSprintHold(false)
		funcs.setIdle(true)
	end
end

function funcs.handleHumanoidMove()
	if not gunInfo then return end
	if not MovementController.isSprinting() then return end

	if GunReloadController.isReloading() then
		funcs.setSprintHold(false)
		funcs.setIdle(true)
		return
	end

	if sprintHold and humanoid.MoveDirection.Magnitude == 0 then
		funcs.setSprintHold(false)
		funcs.setIdle(true)
	elseif not sprintHold and humanoid.MoveDirection.Magnitude ~= 0 then
		funcs.setSprintHold(true)
		funcs.setPatrol(false)
		funcs.setIdle(false)
	end
end

function funcs.handleFireGun()
	funcs.setPatrol(false)
end

function funcs.handleReloadStarted(_duration: number)
	funcs.setPatrol(false)
end

function funcs.setIdle(value: boolean)
	if not gunInfo then return end
	if idle == value then return end

	local idleAnim: AnimationTrack? = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("Idle"))
	if not idleAnim then return end

	idle = value
	if value then idleAnim:Play()
	else idleAnim:Stop() end
end

function funcs.setSprintHold(value: boolean)
	if not gunInfo then return end
	if sprintHold == value then return end

	local sprintHoldAnim: AnimationTrack? = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("SprintHold"))
	if not sprintHoldAnim then return end

	sprintHold = value
	if value then sprintHoldAnim:Play()
	else sprintHoldAnim:Stop() end
end

function funcs.setPatrol(value: boolean)
	if not gunInfo then return end
	if patrol == value then return end

	local patrolAnim: AnimationTrack? = BackpackController.resolveAnim(gunInfo.Tool, gunInfo.Config.DecorConfig.AnimationsFolder:FindFirstChild("Patrol"))
	if not patrolAnim then return end
	patrolAnim.Priority = Enum.AnimationPriority.Action2

	patrol = value
	if value then patrolAnim:Play()
	else patrolAnim:Stop() end
end

player.CharacterAdded:Connect(function(newCharacter: Model)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
end)

-- SUBSCRIPTIONS
RunService.Heartbeat:Connect(funcs.handleHumanoidMove)
UserInputService.InputBegan:Connect(funcs.handleInputBegan)
-- custom
BackpackController.GunEquipped:connect(funcs.handleGunEquipped)
BackpackController.GunUnequipped:connect(funcs.handleGunUnequipped)
GunFireController.FireGun:connect(funcs.handleFireGun)
GunReloadController.ReloadStarted:connect(funcs.handleReloadStarted)
MovementController.SprintStateChanged:connect(funcs.handleSprintStateChange)

return module
