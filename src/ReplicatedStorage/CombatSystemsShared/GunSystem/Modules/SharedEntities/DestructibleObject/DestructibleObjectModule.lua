--!strict

local DestructibleObject = {}
DestructibleObject.__index = DestructibleObject

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.DestructibleObjectConfig)
local DestructibleObjectUtil = require(script.Parent.DObjectUtilModule)

export type SelfObject = typeof(setmetatable({}, DestructibleObject)) & {
	object: Instance,
	HealthChanged: RBXScriptSignal,
}

-- search up until first ancestor with destructible object tag is found, if nothing found - return nil
function DestructibleObject.fromInstanceChild(instance: Instance): SelfObject?
	local objectAncestor: Instance? = instance
	while objectAncestor do
		if objectAncestor:HasTag(DestructibleObjectConfig.Tag) then break end
		objectAncestor = objectAncestor.Parent
	end

	if objectAncestor then
		return DestructibleObject.fromInstance(objectAncestor)
	else
		return nil
	end
end

function DestructibleObject.fromInstance(instance: Instance): SelfObject
	DestructibleObjectUtil.parseValidateObject(instance)
	local self = setmetatable({}, DestructibleObject) :: SelfObject
	self.object = instance
	self.HealthChanged = instance:GetAttributeChangedSignal(DestructibleObjectConfig.HealthAttribute)
	return self
end

function DestructibleObject:takeDamage(amount: number)
	local self = self :: SelfObject
	local health = self:getHealth()
	self:setHealth(math.max(0, health - amount))
end

function DestructibleObject:isDestroyed()
	local self = self :: SelfObject
	return self:getHealth() <= 0
end

function DestructibleObject:getMaxHealth(): number
	local self = self :: SelfObject
	return self.object:GetAttribute(DestructibleObjectConfig.MaxHealthAttribute) :: number
end

function DestructibleObject:getHealth(): number
	local self = self :: SelfObject
	return self.object:GetAttribute(DestructibleObjectConfig.HealthAttribute) :: number
end

function DestructibleObject:setMaxHealth(maxHealth: number)
	local self = self :: SelfObject
	return self.object:SetAttribute(DestructibleObjectConfig.MaxHealthAttribute, maxHealth)
end

function DestructibleObject:setHealth(health: number)
	local self = self :: SelfObject
	return self.object:SetAttribute(DestructibleObjectConfig.HealthAttribute, health)
end

return DestructibleObject
