--!strict
--[[
	MoneyLedger — PROTÓTIPO (auditoria do Ranking Magnata). NÃO está ligado ao jogo.
	Usado pelo simulador (tools/sim/EconomyModel) e pelos testes de exploit
	(tests/MoneyLedger.spec.luau). Ver MAGNATE_RANKING_AUDIT.md.

	LifetimeMoneyGenerated = riqueza PRODUZIDA pela conta durante a vida:
	    - só cresce com fontes GENERATED;
	    - nunca diminui (gastar, Dice, Player Aura, Rebirth não mexem nele);
	    - não reseta no Rebirth; vai no save.
	Toda entrada de dinheiro passa por UMA função (grant) com a ORIGEM registrada; origem
	desconhecida é recusada (falha fechada: nenhum sistema "esquece" de classificar).

	Classes:
	    GENERATED  produzida pelo jogo para a conta a partir da renda/jogo (conta no ranking)
	    TRANSFER   veio de outro jogador (não cria riqueza nova)
	    REFUND     devolução de algo que o próprio jogador pagou (investimento em níveis)
	    RECYCLED   conversão de item em dinheiro (venda): não é produção nova
	    OTHER      Robux, Jackpot (gemas podem ser compradas), DEV/admin: não conta
]]

local MoneyLedger = {}

MoneyLedger.Kinds = { GENERATED = "GENERATED", TRANSFER = "TRANSFER", REFUND = "REFUND", RECYCLED = "RECYCLED", OTHER = "OTHER" }

-- Origens REAIS de EconomyService.AddMoney (servidor) + as do simulador (SellUpgraded).
MoneyLedger.Sources = {
	Collector = "GENERATED", -- renda das estações (coletor da base)
	Offline = "GENERATED", -- renda offline (% da renda, teto pelo próximo Rebirth)
	Tower = "GENERATED", -- 1ª vitória de cada andar (uma vez por andar, para sempre)
	Mission = "GENERATED", -- missões diárias (uma vez por missão por dia)
	Daily = "GENERATED", -- recompensa diária (uma vez por dia)
	Sell = "RECYCLED", -- venda: valor-base = RECYCLED; parte do investimento = REFUND (grantSale)
	AutoSell = "RECYCLED", -- venda automática no roll (valor-base, sem investimento)
	SellUpgraded = "RECYCLED", -- (simulador) troca de estação: venda da antiga
	Refund = "REFUND", -- parte "investimento em níveis" de uma venda
	Trade = "TRANSFER", -- reservado: hoje as trocas NÃO movem dinheiro
	Jackpot = "OTHER", -- prêmio em dinheiro do Jackpot: gemas podem vir de Robux
	Product = "OTHER", -- pacotes de dinheiro em Robux
	Admin = "OTHER", -- compensação administrativa (não existe hoje)
	Dev = "OTHER", -- comandos DEV (só Studio)
}

-- teto de UMA entrada e do total (bem acima de qualquer valor real; protege contra overflow/bug)
MoneyLedger.MaxGrant = 1e18
MoneyLedger.MaxLifetime = 1e24
-- ids de operação lembrados para idempotência (replay de remote / grant duplicado)
MoneyLedger.OpHistory = 200

function MoneyLedger.kindOf(source: string): string?
	return MoneyLedger.Sources[source]
end

function MoneyLedger.counts(source: string): boolean
	return MoneyLedger.Sources[source] == "GENERATED"
end

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- Perfil mínimo usado pelo protótipo (mesmos nomes que iriam para o save)
export type Data = { Money: number, LifetimeMoneyGenerated: number?, LedgerOps: { string }? }

local function remembered(data: Data, opId: string?): boolean
	if not opId then
		return false
	end
	for _, id in data.LedgerOps or {} do
		if id == opId then
			return true
		end
	end
	return false
end

local function remember(data: Data, opId: string?)
	if not opId then
		return
	end
	local ops = data.LedgerOps or {}
	data.LedgerOps = ops
	table.insert(ops, opId)
	while #ops > MoneyLedger.OpHistory do
		table.remove(ops, 1)
	end
end

--[[
	Entrada de dinheiro (ÚNICA porta). Só o servidor chama; nenhum remote recebe valor do cliente.
	Retorna (ok, motivo). opId opcional: a mesma operação aplicada 2× não credita 2×.
]]
function MoneyLedger.grant(data: Data, amount: any, source: any, opId: string?): (boolean, string?)
	if type(source) ~= "string" or MoneyLedger.Sources[source] == nil then
		return false, "unknown_source"
	end
	if not finite(amount) or amount < 0 then
		return false, "invalid_amount"
	end
	if amount > MoneyLedger.MaxGrant then
		return false, "too_large"
	end
	if remembered(data, opId) then
		return false, "duplicate"
	end
	local value = math.floor(amount)
	data.Money += value
	if MoneyLedger.Sources[source] == "GENERATED" then
		data.LifetimeMoneyGenerated = math.min((data.LifetimeMoneyGenerated or 0) + value, MoneyLedger.MaxLifetime)
	end
	remember(data, opId)
	return true, nil
end

-- Venda: valor-base (RECYCLED) e reembolso do investimento (REFUND) separados; nenhum conta
function MoneyLedger.grantSale(data: Data, base: number, refund: number, opId: string?): (boolean, string?)
	local ok, why = MoneyLedger.grant(data, base, "Sell", opId)
	if not ok then
		return ok, why
	end
	return MoneyLedger.grant(data, refund, "Refund", opId and (opId .. ":refund"))
end

-- Gasto (Dice, Aura, níveis, fusão...): só o saldo; o Lifetime NUNCA muda
function MoneyLedger.spend(data: Data, amount: any): boolean
	if not finite(amount) or amount < 0 or data.Money < amount then
		return false
	end
	data.Money -= math.floor(amount)
	return true
end

-- Rebirth: zera o saldo; o Lifetime fica
function MoneyLedger.rebirth(data: Data)
	data.Money = 0
end

-- Pontuação no OrderedDataStore (só inteiros): milhares de $ (precisão de $1K), com teto 2^53
function MoneyLedger.score(lifetime: number): number
	if not finite(lifetime) or lifetime <= 0 then
		return 0
	end
	return math.min(math.floor(lifetime / 1000), 2 ^ 53)
end

-- Migração: os saves atuais NÃO têm histórico de geração; começa em 0 (ver MAGNATE_RANKING_AUDIT.md)
function MoneyLedger.migrate(data: any)
	if type(data.LifetimeMoneyGenerated) ~= "number" or not finite(data.LifetimeMoneyGenerated) or data.LifetimeMoneyGenerated < 0 then
		data.LifetimeMoneyGenerated = 0
	end
	if type(data.LedgerOps) ~= "table" then
		data.LedgerOps = {}
	end
end

return MoneyLedger
