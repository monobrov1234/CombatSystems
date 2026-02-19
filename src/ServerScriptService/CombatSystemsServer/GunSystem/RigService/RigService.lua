--!strict

local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local GunSystemConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.GunSystemConfig)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)

-- FINALS
local log = Logger.new("GunRigService")

-- PUBLIC API
function module.rigGuns(instance: Instance)
	for _, descendant: Instance in instance:GetDescendants() do
		module.rigGun(descendant)
	end
end

function module.rigGun(instance: Instance)
	if not instance:IsA("Tool") or not GunUtil.validateGun(instance) then return end
	local gunInfo: GunUtil.GunInfo = GunUtil.parseGunInfo(instance)

	local function putSound(name: string, sound: Sound?, parent: Instance)
		if not sound then return end
		local clone = sound:Clone()
		clone.Name = name
		clone.Parent = parent
	end

	local soundConfig = gunInfo.Config.DecorConfig.SoundsConfig
	putSound("Fire", soundConfig.FireSound, gunInfo.FiringPoint)
	putSound("Reload", soundConfig.ReloadSound, gunInfo.AnimPart)
end

function funcs.startupRigGuns()
	for _, tagged: Instance in ipairs(CollectionService:GetTagged(GunSystemConfig.RigGunsTag)) do
		log:debug("Rigging guns in {}", tagged.Name)
		module.rigGuns(tagged)
	end

	log:debug("Gun rigging done")
end
funcs.startupRigGuns()

return module
