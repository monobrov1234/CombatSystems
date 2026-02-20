local module = {}
module.__index = module

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local mouse = player:GetMouse()
local _character = player.Character or player.CharacterAdded:Wait()

local guiRoot = playerGui:WaitForChild("CombatSystemsGui")
local gunSystemGui = guiRoot:WaitForChild("GunSystemGui")
local cursorGui = gunSystemGui:WaitForChild("GunCursor")
local hudGui = gunSystemGui:WaitForChild("GunHud")

-- FINALS
local reloadBarMargin = 0.04

export type SelfObject = typeof(setmetatable({}, module)) & {
	-- FINALS
	cleaner: ConnectionCleaner.SelfObject,
	gunInfo: GunUtil.GunInfo,
	-- STATE
	reloadBarClone: typeof(StarterGui.CombatSystemsGui.GunSystemGui.GunCursor.ReloadBar)?,
}
function module.new(gunInfo: GunUtil.GunInfo): SelfObject
	local self = setmetatable({}, module) :: SelfObject
	self.cleaner = ConnectionCleaner.new()
	self.gunInfo = gunInfo
	return self
end

function module:destroy()
	self.cleaner:disconnectAll()
	if self.reloadBarClone then self.reloadBarClone:Destroy() end
end

function module:enableGui()
	hudGui.Frame.GunName.Text = self.gunInfo.Tool.Name
	hudGui.Frame.GunDescription.Text = self.gunInfo.Config.Description
	hudGui.Enabled = true
end

function module:disableGui()
	hudGui.Enabled = false
end

function module:updateHud(magSize: number, ammoSize: number)
	hudGui.Frame.Ammo.MagSize.Text = magSize
	hudGui.Frame.Ammo.AmmoSize.Text = ammoSize
end

function module:startReload()
	self.reloadBarClone = cursorGui.ReloadBar:Clone()
	local inset = GuiService:GetGuiInset()
	self.reloadBarClone.Position = UDim2.new(0, mouse.X + inset.X, reloadBarMargin, mouse.Y + inset.Y)
	self.reloadBarClone.Parent = cursorGui

	local startTime = os.clock()
	local connection: RBXScriptConnection
	connection = self.cleaner:add(RunService.PreSimulation:Connect(function()
		local progress = math.clamp((os.clock() - startTime) / self.gunInfo.Config.GunConfig.ReloadDuration, 0, 1)
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

player.CharacterAdded:Connect(function(newCharacter) -- if player respawns, those values will become invalid so we update them
	_character = newCharacter
	guiRoot = playerGui:WaitForChild("CombatSystemsGui")
	gunSystemGui = guiRoot:WaitForChild("GunSystemGui")
	cursorGui = gunSystemGui:WaitForChild("GunCursor")
	hudGui = gunSystemGui:WaitForChild("GunHud")
end)

return module
