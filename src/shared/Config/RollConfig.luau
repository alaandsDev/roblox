--!strict
-- Configuração do roll (o coração do jogo). Ver RNG.md.

return {
	--[[
		Velocidade do roll: ÚNICA fonte de verdade (servidor valida; cliente só mostra).
		Vale para roll manual, AUTO e OCULTAR (OCULTAR só tira a animação, não acelera).
		    normal          1 roll a cada BaseInterval      = 1 roll/s  (60/min, 3.600/h no máximo)
		    Roll Rápido     1 roll a cada FastRollInterval  = 2 rolls/s (120/min, 7.200/h no máximo)
		Sem folga de rede e sem "crédito": o próximo roll só vale BaseInterval depois do último
		ACEITO pelo servidor (atraso de rede nunca vira rajada de rolls).
		UpgradesAffectInterval = false: a melhoria "Velocidade de Roll" e o perk "Mãos Rápidas"
		NÃO mudam o intervalo (não empilham com o Roll Rápido) e ficam fora da loja.
	]]
	RollSpeed = {
		BaseInterval = 1.0,
		FastRollInterval = 0.5,
		UpgradesAffectInterval = false,
		-- Só usado se UpgradesAffectInterval = true: o intervalo nunca fica abaixo disso
		MinInterval = 0.5,
	},

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

	-- AUTO: espera extra depois do intervalo (0 = cadência exata; o servidor valida cada roll)
	AutoRollExtraDelay = 0,

	-- Histórico de sessão (só memória, não é salvo)
	HistorySize = 10,

	-- Inventário
	InventoryBaseCapacity = 100,

	-- Raridades que nunca podem ser vendidas automaticamente
	ProtectedFromAutoSell = { "Secret" },
}
