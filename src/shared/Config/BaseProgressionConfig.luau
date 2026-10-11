--!strict
--[[
	Quais andares e slots da base cada Rebirth libera.

	Regra: vale o marco com o MAIOR rebirth que seja <= rebirth do jogador.
	(Ex.: com marcos 0 e 5, os Rebirths 1-4 usam o marco 0.)

	Regra final (Fase 8): cada Rebirth libera +1 slot, em ordem.
	  RB0: Floor01; slots 1-4 (LADO A inteiro); 5-8 (LADO B) bloqueados.
	  RB1..RB4: slots 5, 6, 7, 8 (lado B, um por rebirth).
	  RB5: Floor02 é construído; Slot09 liberado (total 9).
	  ... +1 slot por rebirth; Floor03 no RB13, Floor04 no RB21, Floor05 no RB29.
	  RB36: 40 slots (5 andares completos) — último marco.

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

local START_SLOTS = 4
local SLOTS_PER_FLOOR = 8
local MAX_SLOTS = 40

local milestones: { [number]: Milestone } = {}
local previousFloors = 1
for rebirth = 0, MAX_SLOTS - START_SLOTS do
	local count = START_SLOTS + rebirth
	local slots = {}
	for slot = 1, count do
		table.insert(slots, slot)
	end
	local floors = math.ceil(count / SLOTS_PER_FLOOR)
	milestones[rebirth] = {
		UnlockedFloors = floors,
		UnlockedSlots = slots,
		NewFloor = if floors > previousFloors then floors else nil,
	}
	previousFloors = floors
end

local BaseProgressionConfig: { Milestones: { [number]: Milestone } } = {
	Milestones = milestones,
}

return BaseProgressionConfig
