--!strict
--[[
	Quais andares e slots da base cada Rebirth libera.

	Regra: vale o marco com o MAIOR rebirth que seja <= rebirth do jogador.
	(Ex.: com marcos 0 e 5, os Rebirths 1-4 usam o marco 0.)

	Definido até agora:
	  RB0: Floor01 existe; slots 1-4 (LADO A inteiro) liberados; 5-8 (LADO B) bloqueados.
	  RB5: Floor02 é construído; Slot09 liberado (total 9).
	Os Rebirths 1-4 AINDA NÃO FORAM DEFINIDOS: preencha aqui quando forem decididos,
	por exemplo  [2] = { UnlockedFloors = 1, UnlockedSlots = { 1, 2, 3, 4, 5, 6 } }.

	Campos:
	  UnlockedFloors: quantos andares existem fisicamente
	  UnlockedSlots:  lista exata de slots utilizáveis
	  NewFloor:       (opcional) andar construído neste marco (dispara o evento visual)
	  VisualUpgrade:  (opcional) id de melhoria visual da base (usado em fases futuras)
]]

export type Milestone = {
	UnlockedFloors: number,
	UnlockedSlots: { number },
	NewFloor: number?,
	VisualUpgrade: string?,
}

local BaseProgressionConfig: { Milestones: { [number]: Milestone } } = {
	Milestones = {
		[0] = {
			UnlockedFloors = 1,
			UnlockedSlots = { 1, 2, 3, 4 },
		},
		[5] = {
			UnlockedFloors = 2,
			UnlockedSlots = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
			NewFloor = 2,
		},
	},
}

return BaseProgressionConfig
