-- SERVICES
local ServerScriptService = game:GetService("ServerScriptService")

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

local combatSystemsFolder = ServerScriptService:FindFirstChild("CombatSystemsServer")
if combatSystemsFolder then loadModules(combatSystemsFolder) end

local combatSystemsPluginsFolder = ServerScriptService:FindFirstChild("CombatSystemsPlugins")
if combatSystemsPluginsFolder then loadModules(combatSystemsPluginsFolder) end
