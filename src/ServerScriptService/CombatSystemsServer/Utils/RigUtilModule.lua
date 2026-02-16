--!strict

local module = {}

function module.weld(part0: BasePart, part1: BasePart)
	local weld = Instance.new("Weld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	weld.Parent = part0
end

function module.clearWelds(instance: Instance)
	for _, descendant: Instance in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Weld") then descendant:Destroy() end
	end
end

return module
