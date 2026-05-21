local funcs = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local TurretStateService = require(ServerScriptService.CombatSystemsServer.TurretSystem.TurretStateService)

function funcs.handleHumanoidSeated(player: Player, seat: BasePart?)
	if not seat then
		TurretStateService.setPlayerTurretView(player, nil, nil)
		return
	end
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
