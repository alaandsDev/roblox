--!strict
-- TODOS os IDs de monetização ficam aqui. Nunca escreva um ID em outro script.
-- Id = 0 significa "ainda não criado no Creator Hub" (a compra é recusada com aviso).
-- PriceRobux é só para MOSTRAR na loja: mantenha igual ao preço do Creator Hub.
-- Ver MONETIZATION.md (como criar os itens e preencher os IDs).
--
-- Gamepass: { Id, Name, PriceRobux, Effects }  (efeitos aplicados pelo BoostService)
-- Produto:  { Id, Name, PriceRobux }  (entregue por quem chama MonetizationService.RegisterProduct)

export type Item = { Id: number, Name: string, PriceRobux: number, Order: number, Icon: string, Effects: { [string]: any }? }

local MonetizationConfig = {
	GamePasses = {
		-- Renda x1.5, sorte x1.1, etiqueta VIP
		VIP = { Id = 0, Name = "VIP", PriceRobux = 399, Order = 1, Icon = "👑", Effects = { Income = 1.5, Luck = 1.1 } },
		-- Sorte x2 para sempre
		LuckX2 = { Id = 0, Name = "Sorte x2", PriceRobux = 299, Order = 2, Icon = "🍀", Effects = { Luck = 2 } },
		-- +100 espaços na mochila
		BigBackpack = { Id = 0, Name = "Mochila Gigante", PriceRobux = 149, Order = 3, Icon = "🎒", Effects = { Capacity = 100 } },
		-- Roll Rápido: 2 rolls/s (RollConfig.RollSpeed.FastRollInterval); flag, não empilha
		FastRoll = { Id = 0, Name = "Roll Rápido", PriceRobux = 199, Order = 4, Icon = "⚡", Effects = { FastRoll = true } },
	} :: { [string]: Item },

	Products = {
		MoneySmall = { Id = 0, Name = "Pacote de Dinheiro", PriceRobux = 49, Order = 1, Icon = "💵" },
		MoneyLarge = { Id = 0, Name = "Cofre de Dinheiro", PriceRobux = 199, Order = 2, Icon = "💰" },
		LuckBoost = { Id = 0, Name = "Super Sorte 2x (30 min)", PriceRobux = 79, Order = 3, Icon = "🌟" },
		JackpotSpin = { Id = 0, Name = "Giro do Jackpot", PriceRobux = 45, Order = 4, Icon = "🎰" },
		Gems500 = { Id = 0, Name = "500 Gemas", PriceRobux = 99, Order = 5, Icon = "💎" },
	} :: { [string]: Item },

	-- Efeitos dos produtos de dinheiro: max(Min, renda/s * Seconds)
	MoneyPacks = ({
		MoneySmall = { Seconds = 15 * 60, Min = 10_000 },
		MoneyLarge = { Seconds = 2 * 60 * 60, Min = 150_000 },
	} :: { [string]: { Seconds: number, Min: number } }),
	-- Boosts temporários nunca passam de 2x (mesmo teto do Diário e da loja de gemas)
	LuckBoostProduct = { Multiplier = 2, Duration = 30 * 60 },
	GemsProduct = ({ Gems500 = 500 } :: { [string]: number }),
}

return MonetizationConfig
