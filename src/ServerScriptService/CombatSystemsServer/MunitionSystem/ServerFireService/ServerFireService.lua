local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.Signal)

-- PUBLIC EVENTS
module.PreFire = Signal.new()

-- PUBLIC API
function module.serverFireMunition(ray: RayTypeService.RayInfo)
    module.PreFire:fire(ray)
end

return module