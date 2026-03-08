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
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)

-- IMPORTS INTERNAL
local TurretViewController = require(script.Parent.TurretViewController)
local TurretReloadController = require(script.Parent.TurretReloadController)
local TurretDropIndicatorController = require(script.Parent.TurretDropIndicatorController)
local TurretFireController = require(script.Parent.TurretFireController)
local TurretRotationController = require(script.Parent.TurretRotationController)
local TurretStateController = require(script.Parent.TurretStateController)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer
local playerGUI = player.PlayerGui
local mouse = player:GetMouse()
local _character = player.Character or player.CharacterAdded:Wait()

local turretSystemGui = playerGUI:WaitForChild("CombatSystemsGui"):WaitForChild("TurretSystemGui")
local turretHudGui = turretSystemGui:WaitForChild("TurretHud")
local cursorHudGui = turretSystemGui:WaitForChild("TurretCursorHud")

-- FINALS
local log: Logger.SelfObject = Logger.new("TurretGuiController")

local reloadBarYOffset = 40
local cleaner = ConnectionCleaner.new()

-- STATE
local turretInfo: TurretUtil.TurretInfo?
local turretState: TurretUtil.TurretStateInfo?
local reloadBarClone: typeof(StarterGui.CombatSystemsGui.GunSystemGui.TurretViewGui.TurretCursor.ReloadBar)?
local distanceBarClone: typeof(StarterGui.CombatSystemsGui.GunSystemGui.TurretViewGui.TurretCursor.DistanceBar)?

-- INTERNAL FUNCTIONS
function funcs.handleTurretViewSet(newTurretInfo: TurretUtil.TurretInfo)
	turretInfo = newTurretInfo

	turretHudGui.Enabled = true
	cursorHudGui.Cursor.Visible = false
	cursorHudGui.DropIndicator.Visible = false
	cursorHudGui.DistanceBar.Visible = false
	cursorHudGui.Enabled = true

	funcs.rebuildHotbar()
	cleaner:add(RunService.Heartbeat:Connect(funcs.handleUpdateCursor))
	cleaner:add(RunService.Heartbeat:Connect(funcs.handleUpdateCursorHud))
end

function funcs.handleTurretViewCleared()
	cleaner:disconnectAll()

	funcs.hideDropIndicator()
	turretHudGui.Enabled = false
	cursorHudGui.Enabled = false
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

function funcs.handleTurretStateChanged(newTurretState: TurretUtil.TurretStateInfo?)
	if newTurretState then -- keep old value if the state is erased
		turretState = newTurretState
	end

	if not turretInfo then return end
	funcs.rebuildHotbar()
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

function funcs.handleTurretFire()
	-- TODO
end

function funcs.handleUpdateCursorHud()
	assert(turretInfo)
	local centerHud = turretHudGui:FindFirstChild("CenterHud") :: any
	assert(centerHud)

	centerHud.LockIndicator.Visible = TurretRotationController.isTurretLocked()

	if turretState then
		local maxClipSize = turretState.UsingMainGun and turretInfo.TurretConfig.GunConfig.ClipSize or turretInfo.TurretConfig.GunConfig.CoaxConfig.ClipSize
		centerHud.ClipSize.Text = "Clip: " .. tostring(TurretStateController.getCurrentClipSize()) .. "/" .. tostring(maxClipSize)	
		centerHud.CoaxIndicator.Visible = not turretState.UsingMainGun
	end

	if TurretReloadController.isReloading() or TurretReloadController.isReloadingCoax() then
		local reloadEndTime = TurretReloadController.getReloadEndTime()
		local remaining = reloadEndTime - os.clock()
		centerHud.ReloadTimer.Text = string.format("%.1f", remaining):gsub("%.", ",")
	else
		centerHud.ReloadTimer.Text = "0,0"
	end

	if TurretReloadController.isReloading() then
		centerHud.StatusIndicator.Text = "MAIN GUN RELOADING..."
		centerHud.StatusIndicator.Visible = true
	elseif TurretReloadController.isReloadingCoax() then
		centerHud.StatusIndicator.Text = "COAX GUN RELOADING..."
		centerHud.StatusIndicator.Visible = true
	else
		centerHud.StatusIndicator.Visible = false
	end

	centerHud.ElevationIndicator.Text = "ELEV: " .. tostring(math.round(TurretRotationController.getElevation())) .. "°"
end

function funcs.updateHotbar()
	assert(turretInfo and turretState)
	local hotbar = turretHudGui:FindFirstChild("Hotbar") :: Frame
	assert(hotbar)
	local template = hotbar:FindFirstChild("HotbarTemplateItem") :: Frame
	assert(template)

	if turretState.UsingMainGun then
		for _, item: Instance in ipairs(hotbar:GetChildren()) do
			local found = false
			for _, munition in ipairs(turretInfo.TurretConfig.GunConfig.AmmoTypes) do
				if item.Name == munition.name then
					found = true
					break
				end
			end
			
			if not found then continue end

			local item = item :: any
			item.Count.Text = tostring(turretState.MunitionStorage[item.Name])
			item.Icon.SelectedOutline.Transparency = (turretState.SelectedMunition == item.Name) and 0 or 1
		end
	else 
		for _, item: Instance in ipairs(hotbar:GetChildren()) do
			if item.Name == turretInfo.TurretConfig.GunConfig.CoaxConfig.AmmoType then
				local item = item :: any
				item.Count.Text = tostring(turretState.CoaxAmmoSize)
				item.Icon.SelectedOutline.Transparency = 0
			end
		end
	end
end

function funcs.rebuildHotbar()
	assert(turretInfo and turretState)
	local hotbar = turretHudGui:FindFirstChild("Hotbar") :: Frame
	assert(hotbar)
	local template = hotbar:FindFirstChild("HotbarTemplateItem") :: Frame
	assert(template)

	for _, child: Instance in ipairs(hotbar:GetChildren()) do
		if child.Name ~= "HotbarTemplateItem" and child:IsA("Frame") then
			child:Destroy()
		end
	end

	local function initItem(item: Instance, name: string, icon: number?)
		item.Name = name
		local item = item :: any
		item.Title.Text = name

		if icon then
			item.Icon.Image = "rbxassetid://" .. tostring(icon)
		else
			--item.Icon.Image = "rbxassetid://110521765631413"
		end

		item.Visible = true
		item.Parent = hotbar
	end

	if turretState.UsingMainGun then
		for i: number, munition in ipairs(turretInfo.TurretConfig.GunConfig.AmmoTypes) do
			local item = template:Clone()
			initItem(item, munition.name, munition.iconId)
			item.LayoutOrder = i
		end
	else
		local item = template:Clone()
		local coaxConfig = turretInfo.TurretConfig.GunConfig.CoaxConfig
		initItem(item, coaxConfig.AmmoType, coaxConfig.AmmoIconId)
	end

	funcs.updateHotbar()
end

function funcs.startReload(duration: number)
	local barClone = cursorHudGui.ReloadBar:Clone()
	reloadBarClone = barClone
	local inset = GuiService:GetGuiInset()
	barClone.Position = UDim2.new(0, mouse.X + inset.X, 0, mouse.Y + inset.Y + reloadBarYOffset)
	barClone.Parent = cursorHudGui

	local startTime = os.clock()
	local connection: RBXScriptConnection
	connection = cleaner:add(RunService.PreSimulation:Connect(function()
		local progress = math.clamp((os.clock() - startTime) / duration, 0, 1)
		if progress < 1 then
			barClone.Position = UDim2.new(0, mouse.X + inset.X, 0, mouse.Y + inset.Y + reloadBarYOffset)
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
		cursorHudGui.Cursor.Visible = false
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
		cursorHudGui.Cursor.Position = UDim2.new(viewportPoint.X / vpSize.X, 0, viewportPoint.Y / vpSize.Y, 0)
		cursorHudGui.Cursor.Visible = true
	else
		cursorHudGui.Cursor.Visible = false
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
		cursorHudGui.DropIndicator.Position = UDim2.new(viewportPoint.X / vpSize.X, 0, viewportPoint.Y / vpSize.Y, 0)
		cursorHudGui.DropIndicator.Visible = true
	else
		funcs.hideDropIndicator()
	end
end

function funcs.calculateDrop(calcDuration: number, stayDuration: number, munitionName: string)
	if not turretInfo then return end
	local barClone = cursorHudGui.DistanceBar:Clone()
	distanceBarClone = barClone
	barClone.Parent = cursorHudGui

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
	cursorHudGui.DropIndicator.Visible = false
end

-- SUBSCRIPTIONS
TurretViewController.TurretViewSet:connect(funcs.handleTurretViewSet)
TurretViewController.TurretViewCleared:connect(funcs.handleTurretViewCleared)
TurretViewController.TurretStateChanged:connect(funcs.handleTurretStateChanged)
TurretFireController.TurretFired:connect(funcs.handleTurretFire)
TurretReloadController.ReloadStarted:connect(funcs.handleReloadStarted)
TurretDropIndicatorController.DropCalculationRequested:connect(funcs.handleDropCalculationRequested)
TurretDropIndicatorController.DropIndicatorRequested:connect(funcs.handleDropIndicatorRequested)
TurretDropIndicatorController.DropIndicatorHideRequested:connect(funcs.handleDropIndicatorHideRequested)

player.CharacterAdded:Connect(function(newCharacter: Model)
	_character = newCharacter
	turretSystemGui = playerGUI:WaitForChild("CombatSystemsGui"):WaitForChild("TurretSystemGui")
	cursorHudGui = turretSystemGui:WaitForChild("TurretCursorHud")
	turretHudGui = turretSystemGui:WaitForChild("TurretHud")
end)

return module
