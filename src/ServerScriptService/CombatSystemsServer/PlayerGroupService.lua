--!strict

local module = {}

-- IMPORTS
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)

-- FINALS
local log: Logger.SelfObject = Logger.new("PlayerGroupService")
local groupCache: { [number]: { number } } = {} -- player.UserID: {groupId}

-- PUBLIC API
function module.getPlayerGroupIds(player: Player): { number }
	if not player:IsDescendantOf(Players) then
		-- theoretical memory leak prevention, should not happen
		return {}
	end

	local groups: { number }? = groupCache[player.UserId]
	if not groups then
		local success, result: { { Id: number } } = pcall(function()
			return GroupService:GetGroupsAsync(player.UserId)
		end)
		if not success then
			-- should not happen, if it ever happens - nothing will break except player will be unable to use grouplocked vehicles
			warn("failed to get player groups")
			return {}
		end

		local groupIds: { number } = {}
		for _, groupInfo in ipairs(result) do
			table.insert(groupIds, groupInfo.Id)
		end

		groupCache[player.UserId] = groupIds
		return groupIds
	else
		return groups
	end
end

function module.isInAnyWhitelistedGroup(player: Player, groupWhitelist: { number }): boolean
	local groupIds: { number } = module.getPlayerGroupIds(player)
	for _, id: number in ipairs(groupIds) do
		if table.find(groupWhitelist, id) then return true end
	end
	return false
end

Players.PlayerAdded:Connect(function(player: Player)
	local groups: { number } = module.getPlayerGroupIds(player) -- cache groups
	log:info("Cached player {} groups, size {}", player.Name, #groups)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	if groupCache[player.UserId] then
		groupCache[player.UserId] = nil -- remove from group cache
		log:info("Removed player {} from group cache", player.Name)
	end
end)

return module
