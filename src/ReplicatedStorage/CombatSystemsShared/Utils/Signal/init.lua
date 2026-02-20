--!strict

local Signal = {}
local funcs = {}
Signal.__index = Signal

-- IMPORTS INTERNAL
local Connection = require(script.Connection)

-- FINALS
Signal.Priority = {
	LOWEST = 0,
	LOW = 25,
	NORMAL = 50,
	HIGH = 75,
	HIGHEST = 100,
}

export type SelfObject = typeof(setmetatable({}, Signal)) & {
	_connections: { Connection.SelfObject },
	_dirty: boolean,
}

function Signal.new(): SelfObject
	local self = setmetatable({}, Signal) :: SelfObject
	self._connections = {}
	self._dirty = false
	return self
end

function Signal:destroy()
	self = self :: SelfObject
	table.clear(self._connections)
end

function Signal:fire(...)
	self = self :: SelfObject
	funcs.checkSort(self)

	local connections = self._connections
	local i = 1

	-- disconnect-safe loop
	while i <= #connections do
		local connection = connections[i]
		local cancelled = connection:getCallback()(...)
		if typeof(cancelled) == "boolean" and cancelled then return end
		if connections[i] == connection then
			i += 1
		end
	end
end

function Signal:connect(callback: Connection.Callback, priority: number?): Connection.SelfObject
	self = self :: SelfObject
	priority = priority or Signal.Priority.NORMAL

	local connection: Connection.SelfObject
	connection = Connection.new(callback, priority :: number, function()
		funcs.disconnect(self, connection)
	end)

	table.insert(self._connections, connection)
	self._dirty = true
	return connection
end

function funcs:disconnect(connection: Connection.SelfObject)
	self = self :: SelfObject
	local index: number? = table.find(self._connections, connection)
	if index then
		table.remove(self._connections, index)
		self._dirty = true
	end
end

function funcs:checkSort()
	self = self :: SelfObject
	if not self._dirty then return end
	self._dirty = false

	table.sort(self._connections, function(a: Connection.SelfObject, b: Connection.SelfObject)
		return a:getPriority() > b:getPriority()
	end)
end

return Signal
