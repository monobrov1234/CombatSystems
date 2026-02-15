--!strict

local Connection = {}
Connection.__index = Connection

export type Callback = (...any) -> ...any

export type SelfObject = typeof(setmetatable({}, Connection)) & {
	_connectCallback: Callback,
	_priority: number,
	_disconnectCallback: Callback,
	_disconnected: boolean,
}

function Connection.new(callback: Callback, priority: number, disconnectCallback: Callback): SelfObject
	local self = setmetatable({}, Connection) :: SelfObject
	self._connectCallback = callback
	self._priority = priority
	self._disconnectCallback = disconnectCallback
	self._disconnected = false
	return self
end

function Connection:getCallback(): Callback
	local self = self :: SelfObject
	return self._connectCallback
end

function Connection:getPriority(): number
	local self = self :: SelfObject
	return self._priority
end

function Connection:disconnect()
	local self = self :: SelfObject
	if self._disconnected then return end
	self._disconnectCallback()
	self._disconnected = true
end

return Connection
