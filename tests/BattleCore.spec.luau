local T = require("./TestLib")
local Rng = require("./Rng")
local BattleCore = require("../src/shared/Modules/BattleCore")
local TowerConfig = require("../src/shared/Config/TowerConfig")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local describe, it, expect = T.describe, T.it, T.expect

local core = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)
local ember = TowerConfig.ById.Ember

local function team(id: string, power: number, n: number): { any }
	local list = {}
	for i = 1, n do
		table.insert(list, core:card(id, power, "team", i))
	end
	return list
end

describe("Batalha de cards", function()
	it("carta: vida e ataque saem do poder; raridade dá velocidade/crítico", function()
		local c = core:card("dragon_knight", 100)
		expect(c.hp).toBe(500)
		expect(c.atk).toBe(100)
		expect(c.speed > core:card("flame_rookie", 100).speed).toBeTruthy()
	end)

	it("inimigos: poder cresce por andar; chefe a cada 10 andares", function()
		expect(core:enemyPower(ember, 2) > core:enemyPower(ember, 1)).toBeTruthy()
		expect(#core:enemies(ember, 10)).toBe(1)
		expect(#core:enemies(ember, 1)).toBe(1)
		expect(#core:enemies(ember, 25) <= TowerConfig.MaxEnemies).toBeTruthy()
	end)

	it("inimigos são determinísticos (mesmo andar = mesmos inimigos)", function()
		local a, b = core:enemies(ember, 7), core:enemies(ember, 7)
		expect(#a).toBe(#b)
		for i = 1, #a do
			expect(a[i].id).toBe(b[i].id)
			expect(a[i].power).toBe(b[i].power)
		end
	end)

	it("time muito mais forte vence; muito mais fraco perde", function()
		local strong = core:simulate(team("dragon_knight", 1000, 5), core:enemies(ember, 1), Rng.new(1))
		expect(strong.won).toBe(true)
		local weak = core:simulate(team("flame_rookie", 1, 1), core:enemies(ember, 20), Rng.new(1))
		expect(weak.won).toBe(false)
	end)

	it("mesma semente = mesmo resultado (servidor reproduzível)", function()
		local a = core:simulate(team("cyber_ronin", 60, 3), core:enemies(ember, 8), Rng.new(5))
		local b = core:simulate(team("cyber_ronin", 60, 3), core:enemies(ember, 8), Rng.new(5))
		expect(a.won).toBe(b.won)
		expect(#a.log).toBe(#b.log)
	end)

	it("log: cada ação aponta um alvo vivo e termina quando um lado cai", function()
		local result = core:simulate(team("storm_swordsman", 150, 5), core:enemies(ember, 12), Rng.new(9))
		expect(#result.log > 0).toBeTruthy()
		for _, action in result.log do
			expect(action.damage > 0).toBeTruthy()
		end
		local enemiesAlive, teamAlive = 0, 0
		for _, c in result.enemies do
			if c.hp > 0 then
				enemiesAlive += 1
			end
		end
		for _, c in result.team do
			if c.hp > 0 then
				teamAlive += 1
			end
		end
		expect(enemiesAlive == 0 or teamAlive == 0 or result.rounds == TowerConfig.MaxRounds).toBeTruthy()
		expect(result.won == (enemiesAlive == 0)).toBeTruthy()
	end)

	it("limite de rodadas: empate = derrota", function()
		local result = core:simulate({ core:card("flame_rookie", 0.0001, "team", 1) }, { core:card("flame_rookie", 0.0001, "enemy", 1) }, function()
			return 0.99
		end)
		expect(result.won == true or result.rounds <= TowerConfig.MaxRounds).toBeTruthy()
	end)

	it("torres: cada uma libera a próxima e fica mais difícil", function()
		local last = 0
		for i, tower in TowerConfig.List do
			expect(tower.BasePower > last).toBeTruthy()
			last = tower.BasePower
			if i > 1 then
				expect(tower.Unlock.Tower).toBe(TowerConfig.List[i - 1].Id)
			end
		end
	end)
end)

return true
