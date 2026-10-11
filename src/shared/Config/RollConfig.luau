--!strict
-- Configuração do roll (o coração do jogo). Ver RNG.md.

return {
	-- Tempo entre rolls (segundos). O upgrade "Velocidade de Roll" reduz até MinCooldown.
	BaseCooldown = 1.0,
	MinCooldown = 0.45,
	-- Folga para atraso de rede na checagem do servidor
	CooldownTolerance = 0.06,

	-- Pity: depois de Threshold rolls seguidos sem tirar MinRarity (ou melhor), o próximo
	-- roll é garantido nessa faixa. O contador zera ao tirar a raridade.
	Pity = {
		{ Id = "Legendary", MinRarity = "Legendary", Threshold = 50 },
		{ Id = "Mythic", MinRarity = "Mythic", Threshold = 250 },
	},

	-- AUTO: espera extra depois do cooldown (o servidor valida cada roll do mesmo jeito)
	AutoRollExtraDelay = 0.1,

	-- Histórico de sessão (só memória, não é salvo)
	HistorySize = 10,

	-- Inventário
	InventoryBaseCapacity = 100,

	-- Raridades que nunca podem ser vendidas automaticamente
	ProtectedFromAutoSell = { "Secret" },
}
