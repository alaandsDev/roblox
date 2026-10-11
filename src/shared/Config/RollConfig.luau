--!strict
-- Configuração do roll (o coração do jogo). Ver RNG.md.

return {
	-- Tempo entre rolls (segundos). O upgrade "Velocidade de Roll" reduz até MinCooldown.
	BaseCooldown = 1.0,
	MinCooldown = 0.45,
	-- Folga para atraso de rede na checagem do servidor
	CooldownTolerance = 0.06,

	-- Pity: depois de Threshold rolls seguidos sem tirar MinRarity (ou melhor), o próximo roll
	-- é garantido. Regra (auditoria): o roll é sorteado normalmente; se já saiu MinRarity ou
	-- melhor, fica; senão vira EXATAMENTE MinRarity. Assim o pity nunca aumenta Divino/Secreto.
	-- O contador zera ao tirar a raridade (ou melhor).
	Pity = {
		{ Id = "Legendary", MinRarity = "Legendary", Threshold = 50 },
		{ Id = "Mythic", MinRarity = "Mythic", Threshold = 800 },
	},

	-- Retornos decrescentes da Luck: LuckEfetiva = 1 + (L-1) / (1 + (L-1)/LuckSoftCap)
	-- (Luck 2 -> 1.91; Luck 10 -> 5.26; Luck 30 -> 7.44; nunca passa de 1 + LuckSoftCap)
	LuckSoftCap = 10,

	-- AUTO: espera extra depois do cooldown (o servidor valida cada roll do mesmo jeito)
	AutoRollExtraDelay = 0.1,

	-- Histórico de sessão (só memória, não é salvo)
	HistorySize = 10,

	-- Inventário
	InventoryBaseCapacity = 100,

	-- Raridades que nunca podem ser vendidas automaticamente
	ProtectedFromAutoSell = { "Secret" },
}
