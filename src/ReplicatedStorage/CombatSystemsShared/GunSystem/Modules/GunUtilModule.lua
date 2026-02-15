local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.GunConfig)
local GunConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.GunConfigUtilModule)

-- FINALS
export type GunInfo = {
	Tool: Tool,
	Config: GunConfigUtil.DefaultType,
	AnimPart: BasePart,
	FiringPoint: BasePart,
}

function module.validateGun(gunTool: Tool): boolean
	return gunTool:HasTag(GunConfig.Tag)
end

function module.parseGunInfo(gunTool: Tool): GunInfo
	assert(module.validateGun(gunTool), "Gun " .. gunTool.Name .. " doesn't have gun tag")

	local config = GunConfigUtil.getConfig(gunTool.Name)
	assert(config, "Gun " .. gunTool.Name .. " doesn't have config")

	local animPart = gunTool:FindFirstChild("AnimPart")
	assert(animPart and animPart:IsA("BasePart"), "Gun " .. gunTool.Name .. " doesn't have anim part")

	local firingPoint: BasePart = gunTool:FindFirstChild("Barrel")
	assert(firingPoint and firingPoint:IsA("BasePart"), "Gun " .. gunTool.Name .. " doesn't have Barrel part (firing point)")

	return {
		Tool = gunTool,
		Config = config,
		AnimPart = animPart,
		FiringPoint = firingPoint,
	}
end

return module
