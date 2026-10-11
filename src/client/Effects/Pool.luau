--!strict
--[[
	Pool simples de Instances (destroços, anéis, poeira): reaproveita em vez de criar/destruir
	a cada roll. Objetos devolvidos ficam com Parent = nil.
	    local pool = Pool.new(function() return Instance.new("Part") end, 40)
	    local part = pool:Get()  ...  pool:Release(part)
]]

local Pool = {}
Pool.__index = Pool

function Pool.new(factory: () -> Instance, max: number?): any
	return setmetatable({ factory = factory, free = {} :: { Instance }, max = max or 64, created = 0 }, Pool)
end

function Pool:Get(): any
	local item = table.remove(self.free)
	if item then
		return item
	end
	self.created += 1
	return self.factory()
end

function Pool:Release(item: Instance)
	item.Parent = nil
	if #self.free < self.max then
		table.insert(self.free, item)
	else
		item:Destroy()
	end
end

function Pool:Size(): number
	return #self.free
end

return Pool
