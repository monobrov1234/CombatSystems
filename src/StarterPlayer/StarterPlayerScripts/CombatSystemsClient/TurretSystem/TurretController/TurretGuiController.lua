--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local TurretSystemConfig = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.TurretSystemConfig)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local PredictProjectile = require(ReplicatedStorage.CombatSystemsShared.Libs.PredictProjectile)
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)

-- IMPORTS INTERNAL
local TurretViewController = require(script.Parent.TurretViewController)
local TurretReloadController = require(script.Parent.TurretReloadController)
local TurretDropIndicatorController = require(script.Parent.TurretDropIndicatorController)
local TurretStateController = require(script.Parent.TurretStateController)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer
local playerGUI = player.PlayerGui
local mouse = player:GetMouse()
local _character = player.Character or player.CharacterAdded:Wait()

local guiRoot = playerGUI:WaitForChild("CombatSystemsGui")
local gunSystemGui = guiRoot:WaitForChild("GunSystemGui")
local turretViewGui = gunSystemGui:WaitForChild("TurretViewGui")
local cursorGui = turretViewGui:WaitForChild("TurretCursor")
local hudGui = turretViewGui:WaitForChild("TurretHud")

-- FINALS
local reloadBarMargin = 0.04
local cleaner = ConnectionCleaner.new()

-- STATE
local turretInfo: TurretUtil.TurretInfo?
local reloadBarClone: typeof(StarterGui.CombatSystemsGui.GunSystemGui.TurretViewGui.TurretCursor.ReloadBar)?
local distanceBarClone: typeof(StarterGui.CombatSystemsGui.GunSystemGui.TurretViewGui.TurretCursor.DistanceBar)?

-- INTERNAL FUNCTIONS
function funcs.handleTurretViewSet(newTurretInfo: TurretUtil.TurretInfo)
	turretInfo = newTurretInfo

	hudGui.Enabled = true
	cursorGui.Cursor.Visible = false
	cursorGui.DropIndicator.Visible = false
	cursorGui.DistanceBar.Visible = false
	cursorGui.Enabled = true

	cleaner:add(RunService.PreRender:Connect(funcs.handleUpdateHud))
	cleaner:add(RunService.Heartbeat:Connect(funcs.handleUpdateCursor))
end

function funcs.handleTurretViewCleared()
	cleaner:disconnectAll()

	funcs.hideDropIndicator()
	hudGui.Enabled = false
	cursorGui.Enabled = false
	if reloadBarClone then
		reloadBarClone:Destroy()
		reloadBarClone = nil
	end
	if distanceBarClone then
		distanceBarClone:Destroy()
		distanceBarClone = nil
	end

	turretInfo = nil
end

function funcs.handleReloadStarted(duration: number)
	funcs.startReload(duration)
end

function funcs.handleDropCalculationRequested(calcDuration: number, stayDuration: number, munitionName: string)
	funcs.calculateDrop(calcDuration, stayDuration, munitionName)
end

function funcs.handleDropIndicatorRequested(munitionName: string)
	funcs.updateDropIndicator(munitionName)
end

function funcs.handleDropIndicatorHideRequested()
	funcs.hideDropIndicator()
end

function funcs.handleUpdateHud(deltaTime: number)
	if not turretInfo then return end
	local selected: string? = TurretStateController.getCurrentSelectedMunition()
	hudGui.Frame.AmmoType.Text = selected
	hudGui.Frame.ClipSize.Text = tostring(TurretStateController.getCurrentClipSize())
	hudGui.Frame.AmmoSize.Text = tostring(TurretStateController.getCurrentStoredAmmo())
end

function funcs.startReload(duration: number)
	local barClone = cursorGui.ReloadBar:Clone()
	reloadBarClone = barClone
	local inset = GuiService:GetGuiInset()
	barClone.Position = UDim2.new(0, mouse.X + inset.X, reloadBarMargin, mouse.Y + inset.Y)
	barClone.Parent = cursorGui

	local startTime = os.clock()
	local connection: RBXScriptConnection
	connection = cleaner:add(RunService.PreSimulation:Connect(function()
		local progress = math.clamp((os.clock() - startTime) / duration, 0, 1)
		if progress < 1 then
			barClone.Position = UDim2.new(0, mouse.X + inset.X, reloadBarMargin, mouse.Y + inset.Y)
			barClone.ReloadProgress.Size = UDim2.new(progress, 0, 1, 0)
			barClone.ReloadProgress.Visible = true
			barClone.Visible = true
		else
			barClone:Destroy()
			if reloadBarClone == barClone then reloadBarClone = nil end
			cleaner:disconnect(connection)
		end
	end)) :: RBXScriptConnection
end

function funcs.handleUpdateCursor()
	local turretState = TurretViewController.getCurrentTurretState()
	if not turretState then return end
	assert(turretInfo)

	local selectedMunition: string? = TurretStateController.getCurrentSelectedMunition()
	assert(selectedMunition)
	local config: MunitionConfigUtil.DefaultType? = MunitionConfigUtil.getConfig(selectedMunition)
	assert(config)

	local firingPoint: BasePart? = turretState.UsingMainGun and turretInfo.FiringPoint or turretInfo.FiringPointCoax
	if not firingPoint then
		cursorGui.Cursor.Visible = false
		return
	end

	local raycastParams = TurretStateController.getCurrentRaycastParams()
	assert(raycastParams)

	local origin: Vector3 = firingPoint.Position
	local direction: Vector3 = firingPoint.CFrame.LookVector * config.MaxDistance
	local result: RaycastResult<BasePart>? = workspace:Raycast(origin, direction, raycastParams)

	local hitPosition: Vector3 = result and result.Position or (origin + direction)
	local camera = workspace.CurrentCamera
	local viewportPoint, onScreen = camera:WorldToViewportPoint(hitPosition)
	if onScreen then
		local vpSize = camera.ViewportSize
		cursorGui.Cursor.Position = UDim2.new(viewportPoint.X / vpSize.X, 0, viewportPoint.Y / vpSize.Y, 0)
		cursorGui.Cursor.Visible = true
	else
		cursorGui.Cursor.Visible = false
	end
end

function funcs.updateDropIndicator(munitionName: string)
	assert(turretInfo)
	local config: MunitionConfigUtil.DefaultType? = MunitionConfigUtil.getConfig(munitionName)
	assert(config)

	local firingPoint: BasePart = turretInfo.FiringPoint
	local origin: Vector3 = firingPoint.Position
	local direction: Vector3 = firingPoint.CFrame.LookVector

	local rayParams: RaycastParams? = TurretStateController.getCurrentRaycastParams()
	assert(rayParams)
	local rayResult: RaycastResult = PredictProjectile:ComputeProjectileRaycastHit(
		origin,
		direction * config.BallisticConfig.Speed,
		config.BallisticConfig.Gravity,
		TurretSystemConfig.DropIndicatorConfig.Resolution,
		TurretSystemConfig.DropIndicatorConfig.Steps,
		rayParams)

	local hitPosition: Vector3 = rayResult and rayResult.Position or (origin + (direction * config.MaxDistance))
	local camera = workspace.CurrentCamera
	local viewportPoint: Vector3, onScreen: boolean = camera:WorldToViewportPoint(hitPosition)
	if onScreen then
		local vpSize: Vector2 = camera.ViewportSize
		cursorGui.DropIndicator.Position = UDim2.new(viewportPoint.X / vpSize.X, 0, viewportPoint.Y / vpSize.Y, 0)
		cursorGui.DropIndicator.Visible = true
	else
		funcs.hideDropIndicator()
	end
end

function funcs.calculateDrop(calcDuration: number, stayDuration: number, munitionName: string)
	if not turretInfo then return end
	local barClone = cursorGui.DistanceBar:Clone()
	distanceBarClone = barClone
	barClone.Parent = cursorGui

	local startTime = os.clock()
	local connection: RBXScriptConnection
	connection = cleaner:add(RunService.PreRender:Connect(function()
		if not turretInfo then
			barClone:Destroy()
			if distanceBarClone == barClone then 
				distanceBarClone = nil 
			end
			cleaner:disconnect(connection)
			return
		end

		local progress = math.clamp((os.clock() - startTime) / calcDuration, 0, 1)
		if progress < 1 then
			barClone.ProgressBar.Size = UDim2.new(progress, 0, 1, 0)
			barClone.ProgressBar.Visible = true
			barClone.Visible = true
		else
			barClone:Destroy()
			if distanceBarClone == barClone then distanceBarClone = nil end
			funcs.updateDropIndicator(munitionName)
			cleaner:add(task.delay(stayDuration, funcs.hideDropIndicator))
			cleaner:disconnect(connection)
		end
	end)) :: RBXScriptConnection
end

function funcs.hideDropIndicator()
	cursorGui.DropIndicator.Visible = false
end

-- SUBSCRIPTIONS
TurretViewController.TurretViewSet:connect(funcs.handleTurretViewSet)
TurretViewController.TurretViewCleared:connect(funcs.handleTurretViewCleared)
TurretReloadController.ReloadStarted:connect(funcs.handleReloadStarted)
TurretDropIndicatorController.DropCalculationRequested:connect(funcs.handleDropCalculationRequested)
TurretDropIndicatorController.DropIndicatorRequested:connect(funcs.handleDropIndicatorRequested)
TurretDropIndicatorController.DropIndicatorHideRequested:connect(funcs.handleDropIndicatorHideRequested)

player.CharacterAdded:Connect(function(newCharacter: Model)
	_character = newCharacter
	guiRoot = playerGUI:WaitForChild("CombatSystemsGui")
	gunSystemGui = guiRoot:WaitForChild("GunSystemGui")
	turretViewGui = gunSystemGui:WaitForChild("TurretViewGui")
	cursorGui = turretViewGui:WaitForChild("TurretCursor")
	hudGui = turretViewGui:WaitForChild("TurretHud")
end)

return module
