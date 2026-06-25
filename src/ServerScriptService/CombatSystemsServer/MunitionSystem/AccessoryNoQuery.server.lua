-- This script disables player accessories CanQuery so hitboxes work correctly
-- TODO: if players can change their morphs / accessories at runtime then im not sure this will work in that case
-- this also does not handle NPCs

--!strict

local funcs = {}

-- IMPORTS
local Players = game:GetService("Players")

function funcs.handleCharacterAdded(character: Model)
    local player: Player? = Players:GetPlayerFromCharacter(character)
    if not player then return end
    repeat task.wait() until player:HasAppearanceLoaded()

    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Accessory") then
            local hnd: Instance? = child:FindFirstChild("Handle")
            if hnd and hnd:IsA("BasePart") then
                hnd.CanQuery = false
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player: Player) 
    if player.Character ~= nil then funcs.handleCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(funcs.handleCharacterAdded)
end)