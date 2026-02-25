--!strict

local module = {}
local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CursorConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.CursorConfig)

-- ROBLOX OBJECTS
local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local _character = player.Character or player.CharacterAdded:Wait()
local combatCursorGui = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("MunitionSystemGui"):WaitForChild("Cursor")
local cursorGui = combatCursorGui:WaitForChild("CombatCursor")
local cursorIcon = cursorGui:WaitForChild("CursorIcon")
local cursorSelectionHud = combatCursorGui:WaitForChild("CursorSelectionHud")

-- STATE
local currentCursorId = CursorConfig.Cursors[CursorConfig.DefaultCursor]
local enabled = false
local prevPlayer: Player? = nil
local currentTween: Tween? = nil

-- PUBLIC API
function module.enableCursor()
	UserInputService.MouseIconEnabled = false
	prevPlayer = nil
	enabled = true
end

function module.disableCursor()
	enabled = false
	cursorGui.Enabled = false
	UserInputService.MouseIconEnabled = true
end

function module.setCursor(cursorId: number)
	currentCursorId = cursorId
	cursorIcon.Image = "rbxassetid://" .. tostring(currentCursorId)
end

-- INTERNAL FUNCTIONS
function funcs.handleInput(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if not enabled then return end

	if input.KeyCode == CursorConfig.ChangeMenuKey then cursorSelectionHud.Enabled = true end
end

function funcs.handleInputEnd(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end

	if input.KeyCode == CursorConfig.ChangeMenuKey then funcs.closeCursorChangeGui() end
end

function funcs.handlePreRender()
	if not enabled then return end
	cursorIcon.Position = UDim2.fromOffset(mouse.X, mouse.Y)
	cursorGui.Enabled = true

	local hitPlayer: Player? = funcs.getPlayerAtMouseHit()
	if hitPlayer and prevPlayer ~= hitPlayer then
		if player.Team ~= hitPlayer.Team or not player.Team or not hitPlayer.Team then
			funcs.tweenCursorColor(CursorConfig.EnemyColor)
		else
			funcs.tweenCursorColor(CursorConfig.FriendlyColor)
		end
	end

	if not hitPlayer then
		if currentTween then
			currentTween:Cancel()
			currentTween = nil
		end
		cursorIcon.ImageColor3 = CursorConfig.DefaultColor
	end

	prevPlayer = hitPlayer
end

function funcs.tweenCursorColor(target: Color3)
	local info = TweenInfo.new(CursorConfig.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	currentTween = TweenService:Create(cursorIcon, info, { ImageColor3 = target })
	assert(currentTween)
	currentTween:Play()
end

function funcs.getPlayerAtMouseHit(): Player?
	local mouseHit: BasePart? = mouse.Target
	if not mouseHit then return nil end
	local character: Model? = mouseHit:FindFirstAncestorOfClass("Model")
	if not character then return nil end
	local hitPlayer: Player? = Players:GetPlayerFromCharacter(character)
	if not hitPlayer then return nil end
	return hitPlayer
end

function funcs.fillCursorChangeGui()
	for _, cursorId in ipairs(CursorConfig.Cursors) do
		local templateClone = cursorSelectionHud.ScrollingFrame.CursorTemplate:Clone()
		templateClone.ImageLabel.Image = "rbxassetid://" .. tostring(cursorId)
		templateClone.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				module.setCursor(cursorId)
				funcs.closeCursorChangeGui()
			end
		end)
		templateClone.Visible = true
		templateClone.Parent = cursorSelectionHud.ScrollingFrame
	end
end

function funcs.closeCursorChangeGui()
	cursorSelectionHud.Enabled = false
end

player.CharacterAdded:Connect(function(newCharacter: Model)
	_character = newCharacter
	combatCursorGui = playerGui:WaitForChild("CombatSystemsGui"):WaitForChild("MunitionSystemGui"):WaitForChild("Cursor")
	cursorSelectionHud = combatCursorGui:WaitForChild("CursorSelectionHud")
	cursorGui = combatCursorGui:WaitForChild("CombatCursor")
	cursorIcon = cursorGui:WaitForChild("CursorIcon")
	funcs.fillCursorChangeGui()
	module.setCursor(currentCursorId)
end)

RunService.PreSimulation:Connect(funcs.handlePreRender)
UserInputService.InputBegan:Connect(funcs.handleInput)
UserInputService.InputEnded:Connect(funcs.handleInputEnd)

funcs.fillCursorChangeGui()
module.setCursor(currentCursorId)

return module
