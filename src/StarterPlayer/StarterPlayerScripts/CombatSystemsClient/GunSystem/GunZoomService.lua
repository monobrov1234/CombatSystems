--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.GunSystemConfig)

-- IMPORTS INTERNAL
local BackpackController = require(script.Parent.BackpackController)

-- STATE
local gunInfo: GunUtil.GunInfo?
local baseFOV: number?
local zoomed = false
local zoomTween: Tween?

-- PUBLIC API
function module.isZoomed()
    return zoomed
end

-- INTERNAL FUNCTIONS
function funcs.handleGunEquipped(newGunInfo: GunUtil.GunInfo)
	gunInfo = newGunInfo
    baseFOV = workspace.CurrentCamera.FieldOfView
end

function funcs.handleGunUnequipped()
	funcs.cancelZoomTween()
	workspace.CurrentCamera.FieldOfView = baseFOV
    zoomed = false
	gunInfo = nil
end

function funcs.handleInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not gunInfo then return end

	if input.KeyCode == GunSystemConfig.KeyBindings.ZoomKey then
        local equipped: GunUtil.GunInfo? = BackpackController.getEquippedGun()
        if not equipped or equipped.Tool ~= gunInfo.Tool then return end
    
        local zoomConfig = gunInfo.Config.ZoomConfig
        if not zoomConfig.ZoomEnabled then return end  

		funcs.toggleZoom()
	end
end

function funcs.tweenFOV(targetFOV: number, duration: number)
    funcs.cancelZoomTween()

	local camera = workspace.CurrentCamera
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	zoomTween = TweenService:Create(camera, tweenInfo, { FieldOfView = targetFOV })
    assert(zoomTween)
	zoomTween:Play()
end

function funcs.toggleZoom()
	assert(gunInfo and baseFOV)

	if zoomed then -- exit
        funcs.tweenFOV(baseFOV, gunInfo.Config.ZoomConfig.ZoomTweenDuration)
        zoomed = false
	else -- enter
		local zoomConfig = gunInfo.Config.ZoomConfig
		funcs.tweenFOV(baseFOV - zoomConfig.ZoomStrength, zoomConfig.ZoomTweenDuration)
		zoomed = true
	end
end

function funcs.cancelZoomTween()
	if zoomTween then
		zoomTween:Cancel()
		zoomTween = nil
	end
end

-- SUBSCRIPTIONS
UserInputService.InputBegan:Connect(funcs.handleInputBegan)
BackpackController.GunEquipped:connect(funcs.handleGunEquipped)
BackpackController.GunUnequipped:connect(funcs.handleGunUnequipped)

return module
