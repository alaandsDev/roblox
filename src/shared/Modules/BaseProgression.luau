--!strict
--[[
	Converte Rebirth -> andares/slots liberados, a partir do BaseProgressionConfig.
	Módulo puro (testável fora do Roblox).

	    local progression = BaseProgression.new(BaseProgressionConfig, slotsPerFloor)
	    progression:state(0)              --> { rebirth = 0, unlockedFloors = 1, unlockedSlots = {[1]=true,...}, count = 4 }
	    progression:isSlotUnlocked(0, 5)  --> false
	    progression:slotUnlockRebirth(9)  --> 5   (nil = ainda não definido)
]]

local BaseProgression = {}
BaseProgression.__index = BaseProgression

export type State = {
	rebirth: number, -- marco usado
	unlockedFloors: number,
	unlockedSlots: { [number]: boolean },
	count: number,
	visualUpgrade: string?,
}

function BaseProgression.new(config: any, slotsPerFloor: number): any
	local keys = {}
	for rebirth in config.Milestones do
		table.insert(keys, rebirth)
	end
	table.sort(keys)
	return setmetatable({ config = config, keys = keys, slotsPerFloor = slotsPerFloor }, BaseProgression)
end

-- Maior marco <= rebirth
function BaseProgression:milestoneFor(rebirth: number): number
	local chosen = self.keys[1]
	for _, key in self.keys do
		if key <= rebirth then
			chosen = key
		end
	end
	return chosen
end

function BaseProgression:state(rebirth: number): State
	local key = self:milestoneFor(math.max(0, rebirth))
	local milestone = self.config.Milestones[key]
	local slots = {}
	local count = 0
	for _, slotId in milestone.UnlockedSlots do
		if not slots[slotId] then
			slots[slotId] = true
			count += 1
		end
	end
	return {
		rebirth = key,
		unlockedFloors = milestone.UnlockedFloors,
		unlockedSlots = slots,
		count = count,
		visualUpgrade = milestone.VisualUpgrade,
	}
end

function BaseProgression:isSlotUnlocked(rebirth: number, slotId: number): boolean
	return self:state(rebirth).unlockedSlots[slotId] == true
end

function BaseProgression:isFloorUnlocked(rebirth: number, floor: number): boolean
	return floor <= self:state(rebirth).unlockedFloors
end

-- Primeiro rebirth (nos marcos definidos) que libera o slot; nil se ainda não definido
function BaseProgression:slotUnlockRebirth(slotId: number): number?
	for _, key in self.keys do
		if table.find(self.config.Milestones[key].UnlockedSlots, slotId) then
			return key
		end
	end
	return nil
end

function BaseProgression:floorUnlockRebirth(floor: number): number?
	for _, key in self.keys do
		if self.config.Milestones[key].UnlockedFloors >= floor then
			return key
		end
	end
	return nil
end

-- Confere a configuração; devolve lista de problemas (vazia = ok)
function BaseProgression:validate(maxFloors: number): { string }
	local problems = {}
	if not self.config.Milestones[0] then
		table.insert(problems, "falta o marco do Rebirth 0")
	end
	local previous: State? = nil
	for _, key in self.keys do
		local m = self.config.Milestones[key]
		if m.UnlockedFloors < 1 or m.UnlockedFloors > maxFloors then
			table.insert(problems, `RB{key}: UnlockedFloors fora de 1..{maxFloors}`)
		end
		for _, slotId in m.UnlockedSlots do
			local floor = (slotId - 1) // self.slotsPerFloor + 1
			if slotId < 1 or floor > m.UnlockedFloors then
				table.insert(problems, `RB{key}: slot {slotId} está num andar não liberado`)
			end
		end
		if m.NewFloor and m.NewFloor ~= m.UnlockedFloors then
			table.insert(problems, `RB{key}: NewFloor deve ser igual a UnlockedFloors`)
		end
		local current = self:state(key)
		if previous then
			if current.unlockedFloors < previous.unlockedFloors then
				table.insert(problems, `RB{key}: tem menos andares que o marco anterior`)
			end
			for slotId in previous.unlockedSlots do
				if not current.unlockedSlots[slotId] then
					table.insert(problems, `RB{key}: bloqueia de novo o slot {slotId}`)
				end
			end
		end
		previous = current
	end
	return problems
end

return BaseProgression
