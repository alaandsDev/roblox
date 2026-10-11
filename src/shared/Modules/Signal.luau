--!strict
-- Evento simples (sem Instances). Cada conexão roda em sua própria thread,
-- então um erro em um ouvinte não impede os outros.

local Signal = {}
Signal.__index = Signal

export type Connection = { Disconnect: (self: Connection) -> (), Connected: boolean }

function Signal.new()
	return setmetatable({ _listeners = {} :: { [any]: (...any) -> () } }, Signal)
end

function Signal:Connect(fn: (...any) -> ()): Connection
	local key = {}
	self._listeners[key] = fn
	local connection = { Connected = true }
	function connection.Disconnect(conn: any)
		conn.Connected = false
		self._listeners[key] = nil
	end
	return connection :: any
end

function Signal:Fire(...: any)
	for _, fn in self._listeners do
		task.spawn(fn, ...)
	end
end

function Signal:Wait(): ...any
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	table.clear(self._listeners)
end

return Signal
