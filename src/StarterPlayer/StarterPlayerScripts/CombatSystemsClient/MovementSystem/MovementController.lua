local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage.CombatSystemsShared.MovementSystem.MovementSystemConfig)
local SignalModule = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator

local sprintAnim: AnimationTrack?
local crouchAnim: AnimationTrack?

-- STATE
local sprinting = false
local crouching = false

-- PUBLIC EVENTS
module.SprintStateChanged = SignalModule.new() -- (oldState: boolean, newState: boolean) -> ()
module.CrouchingStateChanged = SignalModule.new() -- (oldState: boolean, newState: boolean) -> ()

-- PUBLIC API
function module.setSprinting(state: boolean)
	if sprinting ~= state then funcs.toggleSprint() end
end

function module.setCrouching(state: boolean)
	if crouching ~= state then funcs.toggleCrouch() end
end

function module.isSprinting()
	return sprinting
end

function module.isCrouching()
	return crouching
end

-- INTERNAL FUNCTIONS
function funcs.handleInput(input: InputObject, gameProcessed: boolean)
	if gameProcessed or not Config.Enabled then return end
	if input.KeyCode == Config.SprintKey then
		if crouching then funcs.toggleCrouch() end
		funcs.toggleSprint()
	elseif input.KeyCode == Config.CrouchKey then
		if sprinting then funcs.toggleSprint() end
		funcs.toggleCrouch()
	end
end

function funcs.toggleSprint()
	if not Config.Enabled then return end
	local oldState = sprinting

	if sprinting then
		sprinting = false
		humanoid.WalkSpeed = Config.DefaultWalkSpeed
		if sprintAnim then
			sprintAnim:Stop()
		end
	else
		sprinting = true
		humanoid.WalkSpeed = Config.SprintWalkSpeed
	end

	module.SprintStateChanged:fire(oldState, sprinting)
end

function funcs.toggleCrouch()
	if not Config.Enabled then return end
	local oldState = crouching

	if crouching then
		crouching = false
		humanoid.WalkSpeed = Config.DefaultWalkSpeed
		humanoid.HipHeight = 0
		if crouchAnim then
			crouchAnim:Stop()
		end
	else
		crouching = true
		humanoid.WalkSpeed = Config.CrouchWalkSpeed
		humanoid.HipHeight = Config.CrouchHipHeight
		if crouchAnim and funcs.canPlayAnimations() then crouchAnim:Play() end
	end

	module.CrouchingStateChanged:fire(oldState, crouching)
end

function funcs.updateAnimations()
	if not funcs.canPlayAnimations() then
		if sprintAnim and sprintAnim.IsPlaying then
			sprintAnim:Stop()
		elseif crouchAnim and crouchAnim.IsPlaying then
			crouchAnim:Stop()
		end

		return
	end

	if humanoid.MoveDirection.Magnitude == 0 then
		-- player not moving
		if sprinting and sprintAnim and sprintAnim.IsPlaying then 
			sprintAnim:Stop()
		 end

		if crouching and crouchAnim then 
			crouchAnim:AdjustSpeed(0) 
		end
	else
		-- player moving
		if sprinting and sprintAnim and not sprintAnim.IsPlaying then 
			sprintAnim:Play() 
		end

		if crouching and crouchAnim then
			if not crouchAnim.IsPlaying then
				crouchAnim:Play()
			elseif crouchAnim.Speed == 0 then
				crouchAnim:AdjustSpeed(1)
			end
		end
	end
end

function funcs.canPlayAnimations()
	local state = humanoid:GetState()
	return state ~= Enum.HumanoidStateType.Flying
		and state ~= Enum.HumanoidStateType.Seated
		and state ~= Enum.HumanoidStateType.Swimming
		and state ~= Enum.HumanoidStateType.Dead
end

function funcs.loadAnimations()
	if Config.SprintAnimation then
		sprintAnim = animator:LoadAnimation(Config.SprintAnimation)
		assert(sprintAnim)
		sprintAnim.Looped = true
	end
	
	if Config.SprintAnimation then
		crouchAnim = animator:LoadAnimation(Config.CrouchAnimation)
	end
end

funcs.loadAnimations()

UserInputService.InputBegan:Connect(funcs.handleInput)
RunService.Heartbeat:Connect(funcs.updateAnimations)

player.CharacterAdded:Connect(function(newCharacter: Model)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	if sprintAnim then sprintAnim:Destroy() end
	if crouchAnim then crouchAnim:Destroy() end
	funcs.loadAnimations()
end)

return module
