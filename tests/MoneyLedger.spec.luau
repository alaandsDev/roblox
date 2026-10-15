-- Ranking Magnata: protótipo do LifetimeMoneyGenerated (tools/sim/MoneyLedger). NÃO está no jogo;
-- estes testes fixam as regras de segurança que a implementação terá de cumprir.
local T = require("./TestLib")
local MoneyLedger = require("../tools/sim/MoneyLedger")
local Rng = require("./Rng")
local describe, it, expect = T.describe, T.it, T.expect

local function fresh(): any
	local data = { Money = 0 }
	MoneyLedger.migrate(data)
	return data
end

local function clone(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = clone(v)
	end
	return c
end

describe("Magnata: o que conta como dinheiro GERADO", function()
	it("conta: coletor, offline, torre, missões e diário", function()
		for _, source in { "Collector", "Offline", "Tower", "Mission", "Daily" } do
			expect(MoneyLedger.kindOf(source)).toBe("GENERATED")
		end
	end)

	it("não conta: venda (RECYCLED), reembolso (REFUND), troca (TRANSFER), Jackpot/Robux/DEV/admin (OTHER)", function()
		expect(MoneyLedger.kindOf("Sell")).toBe("RECYCLED")
		expect(MoneyLedger.kindOf("AutoSell")).toBe("RECYCLED")
		expect(MoneyLedger.kindOf("Refund")).toBe("REFUND")
		expect(MoneyLedger.kindOf("Trade")).toBe("TRANSFER")
		for _, source in { "Jackpot", "Product", "Dev", "Admin" } do
			expect(MoneyLedger.kindOf(source)).toBe("OTHER")
		end
	end)

	it("toda origem tem classe válida", function()
		for _, kind in MoneyLedger.Sources do
			expect(MoneyLedger.Kinds[kind] ~= nil).toBeTruthy()
		end
	end)
end)

describe("Magnata: Lifetime nunca diminui", function()
	it("gastar, comprar Dice, comprar Player Aura e Rebirth não reduzem o Lifetime", function()
		local data = fresh()
		MoneyLedger.grant(data, 850e9, "Collector")
		expect(data.LifetimeMoneyGenerated).toBe(850e9)
		expect(MoneyLedger.spend(data, 400e6)).toBe(true) -- Dice
		expect(MoneyLedger.spend(data, 250e9)).toBe(true) -- Player Aura
		expect(MoneyLedger.spend(data, 100e9)).toBe(true) -- níveis
		MoneyLedger.rebirth(data)
		expect(data.Money).toBe(0)
		expect(data.LifetimeMoneyGenerated).toBe(850e9)
	end)

	it("gastar além do saldo é recusado e não mexe em nada", function()
		local data = fresh()
		MoneyLedger.grant(data, 10, "Daily")
		expect(MoneyLedger.spend(data, 11)).toBe(false)
		expect(data.Money).toBe(10)
		expect(data.LifetimeMoneyGenerated).toBe(10)
	end)

	it("sequência aleatória de operações: Lifetime monotônico e = soma das entradas GENERATED", function()
		local rand = Rng.new(2026)
		local data = fresh()
		local expected, last = 0, 0
		local sources = { "Collector", "Offline", "Tower", "Mission", "Daily", "Sell", "AutoSell", "Refund", "Jackpot", "Product" }
		for _ = 1, 5000 do
			local r = rand()
			if r < 0.5 then
				local source = sources[math.floor(rand() * #sources) + 1]
				local amount = math.floor(rand() * 1e9)
				MoneyLedger.grant(data, amount, source)
				if MoneyLedger.counts(source) then
					expected += amount
				end
			elseif r < 0.9 then
				MoneyLedger.spend(data, math.floor(rand() * data.Money))
			else
				MoneyLedger.rebirth(data)
			end
			expect(data.LifetimeMoneyGenerated >= last).toBeTruthy()
			last = data.LifetimeMoneyGenerated
		end
		expect(data.LifetimeMoneyGenerated).toBe(expected)
	end)
end)

describe("Magnata: save/load e migração", function()
	it("save/load (cópia profunda do perfil) preserva o Lifetime", function()
		local data = fresh()
		MoneyLedger.grant(data, 123456789, "Collector")
		MoneyLedger.rebirth(data)
		local loaded = clone(data)
		MoneyLedger.migrate(loaded)
		expect(loaded.LifetimeMoneyGenerated).toBe(123456789)
	end)

	it("save antigo (sem o campo, ou corrompido) começa em 0 — nada é estimado de Money/Rebirth", function()
		local old = { Money = 5e12, Rebirths = 17 }
		MoneyLedger.migrate(old)
		expect(old.LifetimeMoneyGenerated).toBe(0)
		for _, bad in { -5, 0 / 0, math.huge, "999" } do
			local d = { Money = 1, LifetimeMoneyGenerated = bad }
			MoneyLedger.migrate(d)
			expect(d.LifetimeMoneyGenerated).toBe(0)
		end
	end)
end)

describe("Magnata: exploits", function()
	it("troca não duplica: dinheiro entre jogadores é TRANSFER (o total do ranking não cresce)", function()
		local a, b = fresh(), fresh()
		MoneyLedger.grant(a, 1e9, "Collector")
		local before = a.LifetimeMoneyGenerated + b.LifetimeMoneyGenerated
		for _ = 1, 50 do -- ida e volta 50×
			MoneyLedger.spend(a, 1e9)
			MoneyLedger.grant(b, 1e9, "Trade")
			MoneyLedger.spend(b, 1e9)
			MoneyLedger.grant(a, 1e9, "Trade")
		end
		expect(a.LifetimeMoneyGenerated + b.LifetimeMoneyGenerated).toBe(before)
	end)

	it("comprar níveis → vender → repetir não fabrica Lifetime (venda RECYCLED + reembolso REFUND)", function()
		local data = fresh()
		MoneyLedger.grant(data, 1e9, "Collector")
		for _ = 1, 100 do
			local invested = 2e8
			MoneyLedger.spend(data, invested)
			MoneyLedger.grantSale(data, 5e6, math.floor(invested * 0.75))
		end
		expect(data.LifetimeMoneyGenerated).toBe(1e9)
	end)

	it("fusão (só custo) não cria Lifetime", function()
		local data = fresh()
		MoneyLedger.grant(data, 1e9, "Tower")
		MoneyLedger.spend(data, 3e8)
		expect(data.LifetimeMoneyGenerated).toBe(1e9)
	end)

	it("replay de remote / grant duplicado: o mesmo opId só credita uma vez", function()
		local data = fresh()
		expect(MoneyLedger.grant(data, 5000, "Mission", "mission:day42:roll100")).toBe(true)
		local ok, why = MoneyLedger.grant(data, 5000, "Mission", "mission:day42:roll100")
		expect(ok).toBe(false)
		expect(why).toBe("duplicate")
		expect(data.Money).toBe(5000)
		expect(data.LifetimeMoneyGenerated).toBe(5000)
	end)

	it("histórico de opIds é limitado (o save não cresce para sempre)", function()
		local data = fresh()
		for i = 1, MoneyLedger.OpHistory + 50 do
			MoneyLedger.grant(data, 1, "Daily", "op" .. i)
		end
		expect(#data.LedgerOps).toBe(MoneyLedger.OpHistory)
	end)

	it("valores negativos, NaN, infinito e não-número são recusados sem efeito", function()
		local data = fresh()
		MoneyLedger.grant(data, 100, "Collector")
		for _, bad in { -1, -1e12, 0 / 0, math.huge, -math.huge, "100", {} } do
			local ok = MoneyLedger.grant(data, bad, "Collector")
			expect(ok).toBe(false)
		end
		expect(MoneyLedger.spend(data, -50)).toBe(false)
		expect(data.Money).toBe(100)
		expect(data.LifetimeMoneyGenerated).toBe(100)
	end)

	it("overflow: entrada acima do teto é recusada; o total satura; a pontuação é inteira e limitada", function()
		local data = fresh()
		expect(MoneyLedger.grant(data, MoneyLedger.MaxGrant * 10, "Collector")).toBe(false)
		data.LifetimeMoneyGenerated = MoneyLedger.MaxLifetime - 1
		MoneyLedger.grant(data, MoneyLedger.MaxGrant, "Collector")
		expect(data.LifetimeMoneyGenerated).toBe(MoneyLedger.MaxLifetime)
		local score = MoneyLedger.score(data.LifetimeMoneyGenerated)
		expect(score).toBe(2 ^ 53)
		expect(MoneyLedger.score(12.4e12)).toBe(12.4e9)
		expect(MoneyLedger.score(-5)).toBe(0)
		expect(MoneyLedger.score(0 / 0)).toBe(0)
	end)

	it("cliente forjando geração: origem desconhecida/não registrada é recusada (falha fechada)", function()
		local data = fresh()
		for _, source in { "Client", "ClientGenerated", "", nil, 42, { "Collector" } } do
			local ok, why = MoneyLedger.grant(data, 1e12, source :: any)
			expect(ok).toBe(false)
			expect(why).toBe("unknown_source")
		end
		expect(data.Money).toBe(0)
		expect(data.LifetimeMoneyGenerated).toBe(0)
	end)
end)

return true
