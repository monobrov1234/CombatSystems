local module = {}
module.__index = module

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
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleanerModule)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer
local playerGUI = player.PlayerGui
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

local guiRoot = playerGUI:WaitForChild("CombatSystemsGui")
local gunSystemGui = guiRoot:WaitForChild("GunSystemGui")
local turretViewGui = gunSystemGui:WaitForChild("TurretViewGui")
local cursorGui = turretViewGui:WaitForChild("TurretCursor")
local hudGui = turretViewGui:WaitForChild("TurretHud")

-- FINALS
local reloadBarMargin = 0.04

export type SelfObject = typeof(setmetatable({}, module)) & {
	-- FINALS
	cleaner: ConnectionCleaner.SelfObject,
	turretInfo: TurretUtil.TurretInfo,
	raycastParams: RaycastParams,
	-- STATE
	reloadBarClone: typeof(StarterGui.CombatSystemsGui.GunSystemGui.TurretViewGui.TurretCursor.ReloadBar)?,
	distanceBarClone: typeof(StarterGui.CombatSystemsGui.GunSystemGui.TurretViewGui.TurretCursor.DistanceBar)?,
}
function module.new(turretInfo: TurretUtil.TurretInfo, raycastParams: RaycastParams): SelfObject
	local self = setmetatable({}, module) :: SelfObject
	self.cleaner = ConnectionCleaner.new()
	self.turretInfo = turretInfo
	self.raycastParams = raycastParams
	return self
end

function module:destroy()
	local self = self :: SelfObject
	self.cleaner:disconnectAll()
	if self.reloadBarClone then self.reloadBarClone:Destroy() end
	if self.distanceBarClone then self.distanceBarClone:Destroy() end
end

function module:enableGui()
	hudGui.Enabled = true
	cursorGui.Cursor.Visible = false
	cursorGui.DropIndicator.Visible = false
	cursorGui.DistanceBar.Visible = false
	cursorGui.Enabled = true
end

function module:disableGui()
	hudGui.Enabled = false
	cursorGui.Enabled = false
	self:hideDropIndicator()
end

function module:updateHud(deltaTime: number, munitionName: string, clipSize: number, ammoSize: number)
	hudGui.Frame.AmmoType.Text = munitionName
	hudGui.Frame.ClipSize.Text = tostring(clipSize)
	hudGui.Frame.AmmoSize.Text = tostring(ammoSize)
end

function module:updateCursor(firingPoint: BasePart, selectedMunition: string)
	local self = self :: SelfObject
	local camera = workspace.CurrentCamera
	if not camera then return end

	local config = MunitionConfigUtil.getConfig(selectedMunition)
	local origin = firingPoint.Position
	local direction = firingPoint.CFrame.LookVector * config.MaxDistance

	local result = workspace:Raycast(origin, direction, self.raycastParams)
	local hitPosition = result and result.Position or (origin + direction)
	local viewportPoint, onScreen = camera:WorldToViewportPoint(hitPosition)
	if onScreen then
		local vpSize = camera.ViewportSize
		cursorGui.Cursor.Position = UDim2.new(viewportPoint.X / vpSize.X, 0, viewportPoint.Y / vpSize.Y, 0)
		cursorGui.Cursor.Visible = true
	else
		cursorGui.Cursor.Visible = false
	end
end

function module:updateDropIndicator(munitionName: string)
	local self = self :: SelfObject
	local camera = workspace.CurrentCamera
	if not camera then return end

	local config = MunitionConfigUtil.getConfig(munitionName)
	local firingPoint = self.turretInfo.FiringPoint
	local origin = firingPoint.Position
	local direction = firingPoint.CFrame.LookVector

	local rayResult: RaycastResult = PredictProjectile:ComputeProjectileRaycastHit(
		origin,
		direction * config.BallisticConfig.Speed,
		config.BallisticConfig.Gravity,
		TurretSystemConfig.DropIndicatorConfig.Resolution,
		TurretSystemConfig.DropIndicatorConfig.Steps,
		self.raycastParams
	)
	local hitPosition = rayResult and rayResult.Position or (origin + (direction * config.MaxDistance))
	local viewportPoint, onScreen = camera:WorldToViewportPoint(hitPosition)
	if onScreen then
		local vpSize = camera.ViewportSize
		cursorGui.DropIndicator.Position = UDim2.new(viewportPoint.X / vpSize.X, 0, viewportPoint.Y / vpSize.Y, 0)
		cursorGui.DropIndicator.Visible = true
	else
		self:hideDropIndicator()
	end
end

function module:hideDropIndicator()
	cursorGui.DropIndicator.Visible = false
end

function module:calculateDrop(callback: () -> ())
	local self = self :: SelfObject
	self.distanceBarClone = cursorGui.DistanceBar:Clone()
	self.distanceBarClone.Parent = cursorGui

	local startTime = os.clock()
	local connection: RBXScriptConnection
	connection = self.cleaner:add(RunService.PreRender:Connect(function()
		local progress = math.clamp((os.clock() - startTime) / self.turretInfo.TurretConfig.DropManualCalcDuration, 0, 1)
		if progress < 1 then
			self.distanceBarClone.ProgressBar.Size = UDim2.new(progress, 0, 1, 0)
			self.distanceBarClone.ProgressBar.Visible = true
			self.distanceBarClone.Visible = true
		else
			self.distanceBarClone:Destroy()
			callback()
			self.cleaner:disconnect(connection)
		end
	end))
end

function module:startReload(duration: number)
	local self = self :: SelfObject
	self.reloadBarClone = cursorGui.ReloadBar:Clone()
	local inset = GuiService:GetGuiInset()
	self.reloadBarClone.Position = UDim2.new(0, mouse.X + inset.X, reloadBarMargin, mouse.Y + inset.Y)
	self.reloadBarClone.Parent = cursorGui

	local startTime = os.clock()
	local connection: RBXScriptConnection
	connection = self.cleaner:add(RunService.PreSimulation:Connect(function()
		local progress = math.clamp((os.clock() - startTime) / duration, 0, 1)
		if progress < 1 then
			self.reloadBarClone.Position = UDim2.new(0, mouse.X + inset.X, reloadBarMargin, mouse.Y + inset.Y)
			self.reloadBarClone.ReloadProgress.Size = UDim2.new(progress, 0, 1, 0)
			self.reloadBarClone.ReloadProgress.Visible = true
			self.reloadBarClone.Visible = true
		else
			self.reloadBarClone:Destroy()
			self.cleaner:disconnect(connection)
		end
	end))
end

player.CharacterAdded:Connect(function(newCharacter: Model) -- if player respawns, these values will become invalid
	character = newCharacter
	guiRoot = playerGUI:WaitForChild("CombatSystemsGui")
	gunSystemGui = guiRoot:WaitForChild("GunSystemGui")
	turretViewGui = gunSystemGui:WaitForChild("TurretViewGui")
	cursorGui = turretViewGui:WaitForChild("TurretCursor")
	hudGui = turretViewGui:WaitForChild("TurretHud")
end)

return module
