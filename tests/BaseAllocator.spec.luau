local T = require("./TestLib")
local BaseAllocator = require("../src/server/Core/BaseAllocator")
local MapConfig = require("../src/shared/Config/MapConfig")
local describe, it, expect = T.describe, T.it, T.expect

describe("BaseAllocator (atribuição de base)", function()
	it("primeiro jogador recebe a primeira base da ordem de preferência", function()
		local alloc = BaseAllocator.new(MapConfig.Bases.AssignOrder)
		expect(alloc:assign(111)).toBe(MapConfig.Bases.AssignOrder[1])
	end)

	it("10 jogadores: 10 bases diferentes, nunca duas pessoas na mesma base", function()
		local alloc = BaseAllocator.new(MapConfig.Bases.AssignOrder)
		local used = {}
		for userId = 1, 10 do
			local id = alloc:assign(userId)
			expect(id ~= nil).toBeTruthy()
			expect(used[id]).toBeNil()
			used[id] = userId
			expect(alloc:owner(id)).toBe(userId)
		end
		expect(alloc:countFree()).toBe(0)
	end)

	it("11º jogador não recebe base (fallback para o Hub) e nada quebra", function()
		local alloc = BaseAllocator.new(MapConfig.Bases.AssignOrder)
		for userId = 1, 10 do
			alloc:assign(userId)
		end
		expect(alloc:assign(11)).toBeNil()
		expect(alloc:baseOfUser(11)).toBeNil()
	end)

	it("pedir de novo devolve a mesma base (sem ocupar outra)", function()
		local alloc = BaseAllocator.new(MapConfig.Bases.AssignOrder)
		local a = alloc:assign(5)
		expect(alloc:assign(5)).toBe(a)
		expect(alloc:countFree()).toBe(9)
	end)

	it("sair libera a base e ela pode ser reatribuída", function()
		local alloc = BaseAllocator.new(MapConfig.Bases.AssignOrder)
		local a = alloc:assign(1)
		alloc:assign(2)
		expect(alloc:release(1)).toBe(a)
		expect(alloc:owner(a)).toBeNil()
		expect(alloc:assign(3)).toBe(a)
		expect(alloc:owner(a)).toBe(3)
	end)

	it("liberar quem não tem base não quebra", function()
		local alloc = BaseAllocator.new(MapConfig.Bases.AssignOrder)
		expect(alloc:release(999)).toBeNil()
	end)

	it("ordem de preferência cobre as 10 bases sem repetir", function()
		local seen = {}
		for _, id in MapConfig.Bases.AssignOrder do
			expect(seen[id]).toBeNil()
			seen[id] = true
		end
		for id = 1, 10 do
			expect(seen[id]).toBe(true)
		end
	end)
end)

return true
