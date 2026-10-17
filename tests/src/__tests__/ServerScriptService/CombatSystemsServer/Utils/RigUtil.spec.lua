-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local RigUtil = require(ServerScriptService.CombatSystemsServer.Utils.RigUtil)
local JestGlobals = require(game:GetService("ReplicatedStorage").Packages.JestGlobals)

-- TEST IMPORTS
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect

describe("RigUtil", function()
	it("welds two parts together", function()
		local part0 = Instance.new("Part")
		local part1 = Instance.new("Part")
		part0.CFrame = CFrame.new(1, 2, 3)
		part1.CFrame = CFrame.new(4, 5, 6)

		RigUtil.weld(part0, part1)

		local weld = part0:FindFirstChildOfClass("Weld")
		assert(weld)
		expect(weld.Part0).toBe(part0)
		expect(weld.Part1).toBe(part1)
		expect(weld.C0).toEqual(part0.CFrame:ToObjectSpace(part1.CFrame))

		part0:Destroy()
		part1:Destroy()
	end)

	it("removes descendant Welds without removing other joints", function()
		local model = Instance.new("Model")
		local part = Instance.new("Part")
		part.Parent = model
		local weld = Instance.new("Weld")
		weld.Parent = part
		local motor = Instance.new("Motor6D")
		motor.Parent = part

		RigUtil.clearWelds(model)

		expect(weld.Parent).toBe(nil)
		expect(motor.Parent).toBe(part)

		model:Destroy()
	end)
end)
