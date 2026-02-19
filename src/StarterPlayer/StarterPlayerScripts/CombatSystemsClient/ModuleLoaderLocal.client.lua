-- SERVICES
local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerScripts = player.PlayerScripts :: typeof(game:GetService("StarterPlayer").StarterPlayerScripts)

local function loadModules(folder: Folder)
	for _, obj: Instance in ipairs(folder:GetDescendants()) do
		if obj:IsA("ModuleScript") then
			local ok, err = pcall(function()
				require(obj)
			end)

			if not ok then error("Failed to load module " .. obj.Name .. ": " .. err) end
		end
	end
end

local function loadFolders(service: Instance)
	local combatSystemsFolder = service:FindFirstChild("CombatSystemsClient")
	if combatSystemsFolder then loadModules(combatSystemsFolder) end
	
	local combatSystemsSharedFolder = service:FindFirstChild("CombatSystemsShared")
	if combatSystemsSharedFolder then loadModules(combatSystemsSharedFolder) end

	local combatSystemsPluginsFolder = service:FindFirstChild("CombatSystemsPlugins")
	if combatSystemsPluginsFolder then loadModules(combatSystemsPluginsFolder) end
end

loadFolders(PlayerScripts)
loadFolders(game:GetService("ReplicatedStorage"))