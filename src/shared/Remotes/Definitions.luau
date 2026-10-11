--!strict
-- Lista de TODOS os remotes do jogo e o formato dos argumentos aceitos.
-- O módulo Net cria os remotes a partir daqui e valida tudo que chega do cliente.
--
-- Requests: o cliente PEDE algo e o servidor responde { ok = true, data = ... }
--           ou { ok = false, code = "..." }. O cliente nunca decide o resultado.
-- Events:   o servidor AVISA o cliente (servidor -> cliente).
-- rate = { capacity, refill }: quantos pedidos seguidos e quantos por segundo depois.

type Rule = { [string]: any }
export type Request = { args: { Rule }, rate: { capacity: number, refill: number } }
export type Definitions = {
	Requests: { [string]: Request },
	Events: { [string]: {} },
	AutoSellRarities: { string }?,
	BatchModes: { string }?,
}

local ID: Rule = { type = "string", maxLength = 40 }
local CONFIG_ID: Rule = { type = "string", maxLength = 48 }

local UID: Rule = { type = "string", maxLength = 24 }
local AUTO_SELL_RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine" }
local BATCH_MODES = { "Duplicates" }
for _, rarity in AUTO_SELL_RARITIES do
	table.insert(BATCH_MODES, "Rarity:" .. rarity)
end

local Definitions: Definitions = {
	Requests = {
		-- Fundação (FASE 1)
		GetSnapshot = { args = {}, rate = { capacity = 5, refill = 1 } },
		SetSetting = {
			args = {
				{ type = "string", enum = { "AutoRoll", "HideRollAnimation", "CameraShake", "ReducedEffects", "Music" } },
				{ type = "boolean" },
			},
			rate = { capacity = 5, refill = 2 },
		},
		RequestPurchase = { args = { CONFIG_ID }, rate = { capacity = 3, refill = 0.5 } },
		-- Tutorial (auditoria): só avança; sem recompensa
		SetTutorialStep = { args = { { type = "number", integer = true, min = 1, max = 7 } }, rate = { capacity = 3, refill = 1 } },

		-- Mapa (FASE 2): botões CENTRO / CASA / LOJA
		RequestTeleport = {
			args = { { type = "string", enum = { "Center", "Home", "Shop" } } },
			rate = { capacity = 3, refill = 1 },
		},

		-- Roll (FASE 3). Sem argumentos: o cliente NUNCA manda raridade, luck ou personagem.
		RequestRoll = { args = {}, rate = { capacity = 6, refill = 4 } },

		-- Inventário e estações da base (FASE 4)
		EquipCharacter = {
			args = { UID, { type = "number", integer = true, min = 1, max = 64, optional = true } },
			rate = { capacity = 10, refill = 5 },
		},
		UnequipCharacter = { args = { UID }, rate = { capacity = 10, refill = 5 } },
		EquipBest = { args = {}, rate = { capacity = 3, refill = 1 } },
		SetCharacterFlag = {
			args = { UID, { type = "string", enum = { "Locked", "Favorite" } }, { type = "boolean" } },
			rate = { capacity = 10, refill = 5 },
		},
		-- Nível individual da estação: só o uid e QUANTOS níveis (o servidor calcula custo e efeito)
		UpgradeCharacter = {
			args = { UID, { type = "number", integer = true, min = 1, max = 100, optional = true } },
			rate = { capacity = 10, refill = 6 },
		},
		CollectMoney = { args = {}, rate = { capacity = 4, refill = 2 } },

		-- Dados e melhorias globais (FASE 5)
		BuyDice = { args = { CONFIG_ID }, rate = { capacity = 4, refill = 1 } },
		EquipDice = { args = { CONFIG_ID }, rate = { capacity = 5, refill = 2 } },
		BuyUpgrade = {
			args = { { type = "string", enum = { "Luck", "Income", "RollSpeed", "Inventory" } } },
			rate = { capacity = 10, refill = 5 },
		},

		-- Venda e Index (FASE 6)
		SellCharacter = { args = { { type = "array", maxItems = 500, of = UID } }, rate = { capacity = 5, refill = 2 } },
		-- confirm = false: só calcula a prévia ("Vender 23 personagens por $4.25K?")
		SellBatch = {
			args = { { type = "string", enum = BATCH_MODES }, { type = "boolean" } },
			rate = { capacity = 5, refill = 1 },
		},
		SetAutoSell = {
			args = { { type = "string", enum = AUTO_SELL_RARITIES }, { type = "boolean" } },
			rate = { capacity = 10, refill = 4 },
		},

		-- Dinheiro offline e recompensas diárias
		ClaimOfflineReward = { args = {}, rate = { capacity = 3, refill = 0.5 } },
		GetDailyStatus = { args = {}, rate = { capacity = 5, refill = 1 } },
		ClaimDaily = { args = {}, rate = { capacity = 3, refill = 0.5 } },

		-- Renascimento, Fusão e Trocas (FASE 8)
		Rebirth = { args = {}, rate = { capacity = 2, refill = 0.5 } },
		BuyRebirthPerk = {
			args = { { type = "string", enum = { "Luck", "Income", "Speed", "Capacity", "Power" } } },
			rate = { capacity = 5, refill = 2 },
		},
		Fuse = { args = { { type = "array", maxItems = 3, of = UID } }, rate = { capacity = 4, refill = 2 } },
		RequestTrade = { args = { { type = "number", integer = true, min = 1, max = 1e12 } }, rate = { capacity = 3, refill = 0.3 } },
		RespondTrade = { args = { { type = "number", integer = true, min = 1, max = 1e12 }, { type = "boolean" } }, rate = { capacity = 5, refill = 1 } },
		SetTradeOffer = { args = { { type = "array", maxItems = 8, of = UID } }, rate = { capacity = 10, refill = 4 } },
		SetTradeReady = { args = { { type = "boolean" } }, rate = { capacity = 10, refill = 4 } },
		ConfirmTrade = { args = {}, rate = { capacity = 5, refill = 2 } },
		CancelTrade = { args = {}, rate = { capacity = 5, refill = 2 } },

		-- Monetização (FASE 10): Jackpot e loja de gemas (Robux passa por RequestPurchase)
		SpinJackpot = { args = {}, rate = { capacity = 3, refill = 1 } },
		BuyGemItem = { args = { CONFIG_ID }, rate = { capacity = 4, refill = 1 } },

		-- Missões (FASE 9)
		ClaimMission = {
			args = { { type = "string", enum = { "Daily", "Achievement" } }, CONFIG_ID },
			rate = { capacity = 6, refill = 2 },
		},

		-- Torres (FASE 7): o servidor simula a batalha e devolve o registro para o cliente animar
		RequestEnterTower = { args = { CONFIG_ID }, rate = { capacity = 3, refill = 1 } },
		SetTowerTeam = { args = { { type = "array", maxItems = 5, of = UID } }, rate = { capacity = 5, refill = 2 } },
	},

	Events = {
		-- Notificação com chave de texto (Localization) + parâmetros
		Notify = {},
		-- Uma chave de primeiro nível dos dados mudou: (chave, novoValor)
		DataChanged = {},
		-- Mudança parcial do inventário (sem reenviar tudo): ({ set = { [uid] = item }, removed = { uid } })
		InventoryDelta = {},
		-- Um andar novo da base foi construído: (andar). Gancho para o efeito visual no cliente
		FloorUnlocked = {},
		-- Dinheiro coletado no coletor da base: (valor)
		MoneyCollected = {},
		-- Abrir uma janela a partir de um prompt do mapa: (nome)
		OpenMenu = {},
		-- Dinheiro offline pendente: (valor, segundos)
		OfflineReward = {},
		-- Anúncio no servidor (drop raro de alguém): (chave, params, nível)
		Announce = {},
		-- Estação melhorada: (uid, nivel) — som/efeito no cliente
		StationUpgraded = {},
		-- Trocas: pedido recebido (deUserId, nome) e estado da sessão (tabela) / encerrada (motivo)
		TradeRequest = {},
		TradeUpdate = {},
		TradeClosed = {},
		-- Prêmio entregue (Jackpot, loja de gemas, produto Robux): (descrição)
		JackpotResult = {},
		-- Só Studio: tocar um reveal sem RNG (DevService "PlayReveal")
		DevReveal = {},
	},
}

Definitions.AutoSellRarities = AUTO_SELL_RARITIES
Definitions.BatchModes = BATCH_MODES

return Definitions
