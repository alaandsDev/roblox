--!strict
--[[
	PRISMA DA COLEÇÃO (o dado exclusivo do Dia 7 do Diário). Ver RNG.md.

	Um "uso de prisma" sorteia no Dice SELECIONADO, mas só entre os personagens que o jogador AINDA
	NÃO descobriu nesse Dice, mantendo as probabilidades relativas do Dice entre eles:
	    P(c | prisma) = P(c | Dice, Luck) / Σ P(elegíveis | Dice, Luck)
	Não muda pesos, Luck nem pity; não garante raridade; Premium/legado/outro Dice nunca entram.
	Dice completo (nada a descobrir) -> recusado SEM gastar o uso.
	Não é vendido (Robux/gemas) nesta fase: os usos vêm só do Diário.
]]

return {
	-- Liga/desliga o Prisma da Coleção inteiro (servidor recusa com "prism_disabled")
	Enabled = true,
	-- Dado que dá acesso ao prisma (OwnedDice)
	DiceId = "Prism",
	-- Usos creditados cada vez que o Diário entrega o Prism (Dia 7). Na 1ª vez o dado é desbloqueado;
	-- nas seguintes o Diário continua dando as gemas de sempre (Fallback) E credita os usos.
	UsesPerReward = 3,
	-- Teto de usos guardados (o excedente de uma recompensa é perdido)
	MaxCharges = 21,
	-- Política de uso: intervalo mínimo entre dois usos (segundos; 0 = sem intervalo)
	CooldownSeconds = 30,
	-- O uso do prisma mexe nos contadores de pity? (false = não incrementa, não dispara, não zera)
	AffectsPity = false,
	-- Conta como roll (data.Rolls, requisito de desbloqueio dos Dice)?
	CountsAsRoll = false,
}
