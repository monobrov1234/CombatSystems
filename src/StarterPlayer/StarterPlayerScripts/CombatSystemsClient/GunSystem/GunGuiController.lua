--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _StarterGui = game:GetService("StarterGui")

local ConnectionCleaner = require(ReplicatedStorage.CombatSystemsShared.Utils.ConnectionCleaner)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)

-- IMPORTS INTERNAL
local BackpackController = require(script.Parent.BackpackController)
local GunFireController = require(script.Parent.GunFireController)
local GunReloadController = require(script.Parent.GunReloadController)

-- ROBLOX OBJECTS
local playerGui = player.PlayerGui
local mouse = player:GetMouse()
local _character = player.Character or player.CharacterAdded:Wait()

local guiRoot = playerGui:WaitForChild("CombatSystemsGui") :: Instance
local gunSystemGui = guiRoot:WaitForChild("GunSystemGui") :: Instance

type GunHudFrame = Frame & { GunName: TextLabel, GunDescription: TextLabel, Ammo: Frame & { MagSize: TextLabel, AmmoSize: TextLabel } }
type GunHudGui = ScreenGui & { Frame: GunHudFrame }
type GunCursorGui = Frame & { ReloadBar: Frame }
type ReloadBarFrame = Frame & { ReloadProgress: Frame }

local cursorGui = gunSystemGui:WaitForChild("GunCursorHud") :: GunCursorGui
local hudGui = gunSystemGui:WaitForChild("GunHud") :: GunHudGui

-- FINALS
local reloadBarMargin = 0.04
local cleaner = ConnectionCleaner.new()

-- STATE
local gunInfo: GunUtil.GunInfo?
local reloadBarClone: ReloadBarFrame?

-- INTERNAL FUNCTIONS
function funcs.handleGunEquipped(newGunInfo: GunUtil.GunInfo)
	gunInfo = newGunInfo

	local state: BackpackController.GunState? = BackpackController.getStateFor(newGunInfo.Tool)
	assert(state)

	hudGui.Frame.GunName.Text = newGunInfo.Tool.Name
	hudGui.Frame.GunDescription.Text = newGunInfo.Config.Description
	funcs.updateHud(state.SharedState.MagSize, state.SharedState.AmmoSize)
	hudGui.Enabled = true
end

function funcs.handleGunUnequipped()
	cleaner:disconnectAll()
	hudGui.Enabled = false
	if reloadBarClone then
		reloadBarClone:Destroy()
		reloadBarClone = nil
	end
	gunInfo = nil
end

function funcs.handleSetGunState(gunTool: Tool, newState: BackpackController.SharedGunState)
	local equipped = BackpackController.getEquippedGun()
	if not equipped or equipped.Tool ~= gunTool then return end
	funcs.updateHud(newState.MagSize, newState.AmmoSize)
end

function funcs.handleReloadStarted(duration: number)
	funcs.startReload(duration)
end

function funcs.handleFireGun()
	local equipped = BackpackController.getEquippedGun()
	if not equipped then return end
	local state = BackpackController.getStateFor(equipped.Tool)
	if not state then return end
	funcs.updateHud(state.SharedState.MagSize, state.SharedState.AmmoSize)
end

function funcs.updateHud(magSize: number, ammoSize: number)
	hudGui.Frame.Ammo.MagSize.Text = tostring(magSize)
	hudGui.Frame.Ammo.AmmoSize.Text = tostring(ammoSize)
end

function funcs.startReload(duration: number)
	if not gunInfo then return end

	local barClone = (cursorGui.ReloadBar:Clone()) :: ReloadBarFrame
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
			if (reloadBarClone :: any) == (barClone :: any) then reloadBarClone = nil end
			cleaner:disconnect(connection)
		end
	end)) :: RBXScriptConnection
end

-- SUBSCRIPTIONS
BackpackController.GunEquipped:connect(funcs.handleGunEquipped)
BackpackController.GunUnequipped:connect(funcs.handleGunUnequipped)
BackpackController.SetGunState:connect(funcs.handleSetGunState)
GunReloadController.ReloadStarted:connect(funcs.handleReloadStarted)
GunFireController.FireGun:connect(funcs.handleFireGun)

player.CharacterAdded:Connect(function(newCharacter: Model)
	_character = newCharacter
	guiRoot = playerGui:WaitForChild("CombatSystemsGui") :: Instance
	gunSystemGui = guiRoot:WaitForChild("GunSystemGui") :: Instance
	cursorGui = gunSystemGui:WaitForChild("GunCursorHud") :: GunCursorGui
	hudGui = gunSystemGui:WaitForChild("GunHud") :: GunHudGui
end)

return module
