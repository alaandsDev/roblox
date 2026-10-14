--!strict
--[[
	Movimento do jogador (fonte ÚNICA; aplicado pelo SERVIDOR no spawn: BaseService).
	Base 16 (padrão Roblox) era lenta para o mapa (Hub ↔ bases ↔ Torre, rampas de 5 andares).
	22 = +37,5%: confortável sem upgrades, sem quebrar rampas/escadas, colisões nem o mobile
	(o jogador continua controlando bem nas rampas de 20 studs e nas esteiras).
	MaxWalkSpeed = teto absoluto para qualquer bônus futuro (ex.: Player Auras, ainda NÃO
	implementadas — ver PLAYER_AURA_ECONOMY_AUDIT.md). Pulo não muda.
]]

local MovementConfig = {
	DefaultWalkSpeed = 16, -- referência (padrão Roblox), só para documentação/testes
	BaseWalkSpeed = 22,
	MaxWalkSpeed = 40,
}

return MovementConfig
