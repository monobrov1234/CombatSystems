--!strict

local DestructibleObject = {}
DestructibleObject.__index = DestructibleObject

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DestructibleObjectConfig = require(ReplicatedStorage.CombatSystemsShared.MunitionSystem.Configs.DestructibleObjectConfig)

export type ArmorInfo = {
	ArmorType: string,
	Resistance: number,
}

export type SelfObject = typeof(setmetatable({}, DestructibleObject)) & {
	object: Instance,
	HealthChanged: RBXScriptSignal,
}

-- search up until the first ancestor with destructible object tag is found, if nothing found - return nil
function DestructibleObject.fromInstanceChild(instance: Instance): SelfObject?
	local objectAncestor: Instance? = instance
	while objectAncestor do
		local dObject: SelfObject? = DestructibleObject.fromInstance(objectAncestor)
		if dObject then
			return dObject
		end

		if objectAncestor:HasTag(DestructibleObjectConfig.Tag) then break end
		objectAncestor = objectAncestor.Parent
	end

	return nil
end

function DestructibleObject.fromInstance(instance: Instance): SelfObject?
	if not DestructibleObject.validateObject(instance) then return nil end
	DestructibleObject.parseValidateObject(instance)
	local self = setmetatable({}, DestructibleObject) :: SelfObject
	self.object = instance
	self.HealthChanged = instance:GetAttributeChangedSignal(DestructibleObjectConfig.HealthAttribute)
	return self
end

function DestructibleObject.parseValidateObject(dObject: Instance)
	assert(DestructibleObject.validateObject(dObject), "Not a destructible object")
	assert(dObject:GetAttribute(DestructibleObjectConfig.MaxHealthAttribute), "Destructible object should have its max health attribute")
	assert(dObject:GetAttribute(DestructibleObjectConfig.HealthAttribute), "Destructible object should have its health attribute")
end

function DestructibleObject.validateObject(dObject: Instance)
	return dObject:HasTag(DestructibleObjectConfig.Tag)
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
