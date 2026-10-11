local T = require("./TestLib")
local SpawnCoordinator = require("../src/server/Core/SpawnCoordinator")
local BaseAllocator = require("../src/server/Core/BaseAllocator")
local describe, it, expect = T.describe, T.it, T.expect

-- Mundo simulado: alocador real + registro das ações
local function world()
	local w = { log = {}, alloc = BaseAllocator.new({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }) }
	w.coord = SpawnCoordinator.new({
		loadCharacter = function(player)
			table.insert(w.log, { "load", player.UserId })
		end,
		placeAtBase = function(player, baseId)
			table.insert(w.log, { "place", player.UserId, baseId })
		end,
		ownerOf = function(baseId)
			return w.alloc:owner(baseId)
		end,
	})
	function w.assign(player)
		local id = w.alloc:assign(player.UserId)
		w.coord:baseAssigned(player, id)
		return id
	end
	-- simula o Roblox criando o personagem depois de um load
	function w.spawn(player)
		w.coord:characterAdded(player)
		w.coord:rootReady(player)
	end
	function w.places(userId)
		local list = {}
		for _, entry in w.log do
			if entry[1] == "place" and entry[2] == userId then
				table.insert(list, entry[3])
			end
		end
		return list
	end
	function w.loads(userId)
		local n = 0
		for _, entry in w.log do
			if entry[1] == "load" and entry[2] == userId then
				n += 1
			end
		end
		return n
	end
	return w
end

local P1, P2 = { UserId = 101 }, { UserId = 202 }

describe("SpawnCoordinator (Player -> Base -> Spawn)", function()
	it("1/2. cada jogador nasce na entrada da própria base", function()
		local w = world()
		w.coord:playerJoined(P1)
		local b1 = w.assign(P1)
		expect(w.loads(101)).toBe(1) -- só carrega depois da base atribuída
		w.spawn(P1)
		w.coord:playerJoined(P2)
		local b2 = w.assign(P2)
		w.spawn(P2)
		expect(w.places(101)[1]).toBe(b1)
		expect(w.places(202)[1]).toBe(b2)
		expect(b1 ~= b2).toBeTruthy()
	end)

	it("personagem NÃO é carregado antes da base existir", function()
		local w = world()
		w.coord:playerJoined(P1)
		expect(w.loads(101)).toBe(0)
	end)

	it("3/4. morte -> respawn volta para a mesma base", function()
		local w = world()
		w.coord:playerJoined(P1)
		w.coord:playerJoined(P2)
		local b1 = w.assign(P1)
		local b2 = w.assign(P2)
		w.spawn(P1)
		w.spawn(P2)
		w.coord:died(P1)
		w.coord:respawnDue(P1)
		w.spawn(P1)
		w.coord:died(P2)
		w.coord:respawnDue(P2)
		w.spawn(P2)
		expect(#w.places(101)).toBe(2)
		expect(w.places(101)[2]).toBe(b1)
		expect(w.places(202)[2]).toBe(b2)
		expect(w.loads(101)).toBe(2)
	end)

	it("5. nunca posiciona na base de outro jogador", function()
		local w = world()
		w.coord:playerJoined(P1)
		w.assign(P1)
		w.coord:characterAdded(P1)
		-- base trocou de dono por fora (situação anormal): não posiciona
		w.alloc:release(101)
		w.alloc:assign(202)
		w.coord:rootReady(P1)
		expect(#w.places(101)).toBe(0)
	end)

	it("6. entradas quase simultâneas, em qualquer ordem de eventos", function()
		local w = world()
		local players = {}
		for i = 1, 10 do
			players[i] = { UserId = 1000 + i }
			w.coord:playerJoined(players[i])
		end
		-- metade recebe base antes do personagem, metade depois (corrida)
		for i = 1, 10, 2 do
			w.assign(players[i])
		end
		for i = 2, 10, 2 do
			w.coord:fallbackDue(players[i]) -- demorou: nasce no Hub
			w.spawn(players[i])
		end
		for i = 2, 10, 2 do
			w.assign(players[i]) -- base chegou: vai para casa
		end
		for i = 1, 10, 2 do
			w.spawn(players[i])
		end
		local used = {}
		for i = 1, 10 do
			local places = w.places(1000 + i)
			expect(#places).toBe(1)
			local baseId = places[1]
			expect(w.alloc:owner(baseId)).toBe(1000 + i)
			expect(used[baseId]).toBeNil()
			used[baseId] = true
			expect(w.loads(1000 + i)).toBe(1) -- carregado uma vez só
		end
	end)

	it("HumanoidRootPart pronto antes da base: espera a base", function()
		local w = world()
		w.coord:playerJoined(P1)
		w.coord:fallbackDue(P1)
		w.spawn(P1)
		expect(#w.places(101)).toBe(0)
		local b = w.assign(P1)
		expect(w.places(101)[1]).toBe(b)
	end)

	it("sem base (11º jogador): nasce no Hub e não quebra", function()
		local w = world()
		for i = 1, 10 do
			local p = { UserId = i }
			w.coord:playerJoined(p)
			w.assign(p)
		end
		local p11 = { UserId = 11 }
		w.coord:playerJoined(p11)
		expect(w.alloc:assign(11)).toBeNil()
		w.coord:fallbackDue(p11)
		w.spawn(p11)
		expect(w.loads(11)).toBe(1)
		expect(#w.places(11)).toBe(0)
	end)

	it("base atribuída antes do registro do jogador (ordem dos PlayerAdded) funciona", function()
		local w = world()
		local b = w.assign(P1) -- sem playerJoined antes
		w.coord:playerJoined(P1) -- chega depois: não pode apagar o estado
		expect(w.loads(101)).toBe(1)
		w.spawn(P1)
		expect(w.places(101)[1]).toBe(b)
	end)

	it("load repetido é ignorado enquanto carrega; jogador que saiu é esquecido", function()
		local w = world()
		w.coord:playerJoined(P1)
		w.assign(P1)
		w.coord:fallbackDue(P1)
		w.coord:respawnDue(P1)
		expect(w.loads(101)).toBe(1)
		w.coord:playerLeft(P1)
		w.coord:rootReady(P1)
		expect(#w.places(101)).toBe(0)
	end)
end)

return true
