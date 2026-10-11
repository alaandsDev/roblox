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
export type Definitions = { Requests: { [string]: Request }, Events: { [string]: {} } }

local ID: Rule = { type = "string", maxLength = 40 }
local CONFIG_ID: Rule = { type = "string", maxLength = 48 }

local Definitions: Definitions = {
	Requests = {
		-- Fundação (FASE 1)
		GetSnapshot = { args = {}, rate = { capacity = 5, refill = 1 } },
		SetSetting = {
			args = {
				{ type = "string", enum = { "AutoRoll", "HideRollAnimation" } },
				{ type = "boolean" },
			},
			rate = { capacity = 5, refill = 2 },
		},
		RequestPurchase = { args = { CONFIG_ID }, rate = { capacity = 3, refill = 0.5 } },

		-- Preparados para as próximas fases (respondem "Em breve!" até serem implementados)
		RequestRoll = { args = {}, rate = { capacity = 10, refill = 10 } },
		RequestEquipCharacter = { args = { ID, { type = "boolean" } }, rate = { capacity = 10, refill = 5 } },
		RequestSellCharacter = {
			args = { { type = "array", maxItems = 500, of = ID } },
			rate = { capacity = 5, refill = 1 },
		},
		RequestEquipDice = { args = { CONFIG_ID }, rate = { capacity = 5, refill = 2 } },
		RequestUpgrade = { args = { CONFIG_ID }, rate = { capacity = 10, refill = 5 } },
		RequestEnterTower = { args = { CONFIG_ID }, rate = { capacity = 3, refill = 0.5 } },
	},

	Events = {
		-- Notificação com chave de texto (Localization) + parâmetros
		Notify = {},
		-- Uma chave de primeiro nível dos dados mudou: (chave, novoValor)
		DataChanged = {},
	},
}

return Definitions
