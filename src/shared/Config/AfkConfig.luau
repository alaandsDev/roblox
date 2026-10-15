--!strict
--[[
	AFK Resilience (ver AFK_RESILIENCE.md). RESILIÊNCIA DE SESSÃO, não "anti-AFK":
	  - nada aqui gera input, simula atividade ou tenta contornar o timeout de inatividade do Roblox;
	  - o estado AFK é só UX/telemetria: NÃO muda RNG, cadência, Luck, pity, Roll Rápido, renda
	    ou recompensas (AFK não é buff nem penalidade).
]]

return {
	-- Sem input REAL (teclado, mouse, toque, controle) por este tempo -> "Idle".
	-- 120 s = mesmo limiar do evento Players.LocalPlayer.Idled do Roblox.
	IdleAfter = 120,

	-- O cliente avisa "houve input real" no máximo a cada N s (telemetria barata, sem spam).
	ActivityReportEvery = 15,

	-- Comportamento da PLATAFORMA (o jogo não controla): o Roblox desconecta quem fica ~20 min
	-- sem input. Só documentação/texto; nenhum código tenta evitar isso.
	PlatformIdleKick = 20 * 60,

	-- Reconexão (ReconnectPolicy): só por APIs oficiais (TeleportService), com limite e espera.
	Reconnect = {
		-- tentativas automáticas por queda (a 1ª pode tentar o MESMO servidor, se ainda existir)
		MaxAttempts = 3,
		-- espera antes de cada tentativa (s)
		Backoff = { 3, 10, 30 },
		-- cliques em RECONECTAR depois das automáticas (input real do jogador), com intervalo mínimo
		MaxManual = 3,
		ManualCooldown = 5,
		-- reconexões AUTOMÁTICAS encadeadas (servidor novo que cai de novo...) antes de parar:
		-- evita ficar pulando de servidor em servidor em loop
		MaxChain = 2,
		ChainWindow = 10 * 60,
	},

	-- AUTO volta sozinho só numa RECONEXÃO, até este tempo depois da saída, e só depois de
	-- save carregado + base + personagem + serviços prontos (ReconnectPolicy.resumeAuto).
	ResumeAutoWindow = 10 * 60,
}
