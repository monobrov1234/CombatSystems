--!strict

local ConnectionCleaner = {}
ConnectionCleaner.__index = ConnectionCleaner

-- SERVICES
local SignalConnection = require(script.Parent.Signal.Connection)

type ConnectionType = RBXScriptConnection | thread | SignalConnection.SelfObject

export type SelfObject = typeof(setmetatable({}, ConnectionCleaner)) & {
	connections: { ConnectionType },
}
function ConnectionCleaner.new(): SelfObject
	local self = setmetatable({}, ConnectionCleaner) :: SelfObject
	self.connections = {}
	return self
end

function ConnectionCleaner:add(connection: ConnectionType): ConnectionType
	local connections = self.connections
	connections[#connections + 1] = connection
	return connection
end

local function disconnectUniversal(connection: ConnectionType)
	if typeof(connection) == "RBXScriptConnection" then
		local connection = connection :: RBXScriptConnection
		connection:Disconnect()
	elseif typeof(connection) == "thread" and connection ~= coroutine.running() then
		local connection = connection :: thread
		task.cancel(connection)
	elseif typeof(connection) == "table" then
		local connection = connection :: SignalConnection.SelfObject
		connection:disconnect()
	end
end

function ConnectionCleaner:disconnect(connection: ConnectionType)
	local self = self :: SelfObject
	local index = table.find(self.connections, connection)
	if index then
		disconnectUniversal(self.connections[index])
		table.remove(self.connections, index)
	end
end

function ConnectionCleaner:disconnectAll()
	local self = self :: SelfObject
	for _, connection in ipairs(self.connections) do
		disconnectUniversal(connection)
	end
	table.clear(self.connections)
end

return ConnectionCleaner
