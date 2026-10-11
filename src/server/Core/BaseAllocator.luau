--!strict
--[[
	Controle de quais bases estão ocupadas (puro, testável fora do Roblox).
	Garante: uma base por jogador e nunca dois jogadores na mesma base.

	    local alloc = BaseAllocator.new({ 3, 8, 2, ... })  -- ordem de preferência
	    alloc:assign(userId)  --> baseId (ou nil se todas ocupadas)
	    alloc:release(userId) --> baseId liberada (ou nil)
]]

local BaseAllocator = {}
BaseAllocator.__index = BaseAllocator

function BaseAllocator.new(order: { number }): any
	local seen = {}
	for _, id in order do
		assert(not seen[id], "base repetida na ordem: " .. tostring(id))
		seen[id] = true
	end
	return setmetatable({
		order = table.clone(order),
		ownerOf = {} :: { [number]: number }, -- baseId -> userId
		baseOf = {} :: { [number]: number }, -- userId -> baseId
	}, BaseAllocator)
end

-- Próxima base livre na ordem de preferência (sem ocupar)
function BaseAllocator:peekFree(): number?
	for _, id in self.order do
		if self.ownerOf[id] == nil then
			return id
		end
	end
	return nil
end

-- Atribui (ou devolve a base que o jogador já tem)
function BaseAllocator:assign(userId: number): number?
	local current = self.baseOf[userId]
	if current then
		return current
	end
	local id = self:peekFree()
	if id then
		self.ownerOf[id] = userId
		self.baseOf[userId] = id
	end
	return id
end

function BaseAllocator:release(userId: number): number?
	local id = self.baseOf[userId]
	if id then
		self.baseOf[userId] = nil
		self.ownerOf[id] = nil
	end
	return id
end

function BaseAllocator:owner(baseId: number): number?
	return self.ownerOf[baseId]
end

function BaseAllocator:baseOfUser(userId: number): number?
	return self.baseOf[userId]
end

function BaseAllocator:countFree(): number
	local free = 0
	for _, id in self.order do
		if self.ownerOf[id] == nil then
			free += 1
		end
	end
	return free
end

return BaseAllocator
