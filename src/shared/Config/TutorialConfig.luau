--!strict
--[[
	Tutorial curto da primeira sessão (auditoria). data.Tutorial = quantos passos já foram feitos
	(0 = novo; Total = terminado). O cliente detecta cada passo pelos próprios dados e avisa o
	servidor (SetTutorialStep), que só aceita AVANÇAR (nunca voltar). Não dá recompensa: não há
	nada para trapacear. Jogadores antigos (Rolls >= VeteranRolls) pulam o tutorial.

	Passos:
	  1 ROLAR            -> Rolls >= 1
	  2 VER O PERSONAGEM -> abriu a MOCHILA
	  3 EQUIPAR          -> algum personagem na base
	  4 IR PARA A BASE   -> chegou perto da base (ou tocou em IR)
	  5 COLETAR          -> dinheiro > 0
	  6 MELHORAR         -> alguma melhoria ou nível de estação
	  7 PRÓXIMO OBJETIVO -> leu e tocou em OK
	Enquanto o passo atual for <= HideSecondaryUntil, botões secundários do HUD ficam escondidos.
]]

return {
	Total = 7,
	Steps = { "roll", "backpack", "equip", "base", "collect", "upgrade", "goal" },
	VeteranRolls = 50,
	HideSecondaryUntil = 3,
	-- Distância (studs) da base que conta como "visitou a base"
	BaseDistance = 70,
}
