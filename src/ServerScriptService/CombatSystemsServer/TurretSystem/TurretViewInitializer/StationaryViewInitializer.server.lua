local funcs = {}

-- IMPORTS
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TurretStateService = require(ServerScriptService.CombatSystemsServer.TurretSystem.TurretStateService)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.Modules.TurretUtil)
local TurretSystemConfig = require(ReplicatedStorage.CombatSystemsShared.TurretSystem.TurretSystemConfig)

function funcs.handleHumanoidSeated(player: Player, seat: BasePart?)
    if not seat then return end
	if TurretStateService.getPlayerCurrentTurret(player) then return end

    -- find target turret model
    if not seat.Parent or not seat.Parent:IsA("Model") then return end
	local turretModel: Model = seat.Parent

    -- verify that it's stationary
    local stationary = false
    for _, folder: Instance in ipairs(CollectionService:GetTagged(TurretSystemConfig.StationaryFolderTag)) do
        if folder:IsAncestorOf(turretModel) then
            stationary = true
            break
        end
    end
    if not stationary then return end

	local turretInfo: TurretUtil.TurretInfo = TurretUtil.parseTurretInfo(turretModel)
	TurretStateService.setPlayerTurretView(player, turretInfo)
end

local function hookSeated(player: Player)
	local function hookCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Seated:Connect(function(active: boolean, seatPart: BasePart)
			funcs.handleHumanoidSeated(player, seatPart)
		end)
	end

	if player.Character then hookCharacter(player.Character) end
	player.CharacterAdded:Connect(hookCharacter)
end

for _, player: Player in ipairs(Players:GetPlayers()) do
	hookSeated(player)
end

Players.PlayerAdded:Connect(function(player: Player)
	hookSeated(player)
end)
