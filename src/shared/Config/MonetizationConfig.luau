--!strict
-- TODOS os IDs de monetização ficam aqui. Nunca escreva um ID em outro script.
-- Id = 0 significa "ainda não criado no Creator Hub" (a compra é recusada com aviso).
--
-- Gamepass: { Id, Name }
-- Produto:  { Id, Name }  (quem entrega o produto é registrado por um Service com
--           MonetizationService.RegisterProduct("Chave", função))

local MonetizationConfig = {
	GamePasses = {
		-- Exemplos para as próximas fases (ainda sem efeito):
		-- VIP = { Id = 0, Name = "VIP" },
		-- AutoRoll = { Id = 0, Name = "Auto Roll" },
	} :: { [string]: { Id: number, Name: string } },

	Products = {
		-- LuckBoost = { Id = 0, Name = "Boost de Sorte" },
	} :: { [string]: { Id: number, Name: string } },
}

return MonetizationConfig
