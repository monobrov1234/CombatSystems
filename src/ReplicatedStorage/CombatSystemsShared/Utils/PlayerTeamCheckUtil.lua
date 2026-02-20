local module = {}

-- PUBLIC API
function module.isInAnyWhitelistedTeam(player: Player, whitelist: { string }): boolean
    if not player.Team then return false end
    for _, team: string in ipairs(whitelist) do
        if player.Team.Name == team then
            return true
        end
    end

    return false
end

return module