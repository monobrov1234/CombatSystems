-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MunitionConfigUtil = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Modules.MunitionConfigUtil)
local RayTypeService = require(ServerScriptService.CombatSystemsServer.MunitionSystem.MunitionService.RayTypeService)
local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("RayTypeService", function()
	it("adds raycast params while preserving ray information", function()
		local origin = Instance.new("Part")
		local raycastParams = RaycastParams.new()
		local rayInfo = {
			Player = nil,
			Team = nil,
			RayId = "ray-1",
			MunitionConfig = MunitionConfigUtil.getDefaultConfig(),
			Origin = origin,
			Body = { InitOriginPos = Vector3.new(1, 2, 3), InitDirection = Vector3.zAxis },
		} :: any

		local serverRayInfo = RayTypeService.convertNonValidRayInfoToServer(rayInfo, raycastParams)

		expect(serverRayInfo.RayId).toBe("ray-1")
		expect(serverRayInfo.Origin).toBe(origin)
		expect(serverRayInfo.RaycastParams).toBe(raycastParams)
		expect(serverRayInfo.Body).toBe(rayInfo.Body)

		origin:Destroy()
	end)

	it("accepts valid client ray requests and hit data", function()
		local origin = Instance.new("Part")
		local player = {} :: any
		local request = {
			RayId = "ray-2",
			MunitionName = "test",
			Origin = origin,
			Body = { InitOriginPos = Vector3.zero, InitDirection = Vector3.zAxis },
		} :: any
		local hit = { HitPos = Vector3.new(0, 0, -10), Hit = origin } :: any

		expect(pcall(function()
			RayTypeService.validatePlayerRayRequest(player, request)
		end)).toBe(true)
		expect(pcall(function()
			RayTypeService.validatePlayerRayHit(player, hit)
		end)).toBe(true)

		origin:Destroy()
	end)

	it("rejects ray hit data with a non-part hit", function()
		local player = {} :: any
		local invalidHit = { HitPos = Vector3.zero, Hit = "not a part" } :: any
		local success = pcall(function()
			RayTypeService.validatePlayerRayHit(player, invalidHit)
		end)

		expect(success).toBe(false)
	end)
end)
