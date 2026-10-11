--!strict
--[[
	Geometria da base: ids, nomes e posições LOCAIS dos slots/andares.
	Módulo puro (sem APIs do Roblox): recebe o BaseConfig e devolve números,
	para ser testado fora do Studio.

	    local layout = BaseLayout.new(BaseConfig)
	    layout:slotId(1, "B", 1)       --> 5
	    layout:slotInfo(9)             --> { floor = 2, side = "A", index = 1 }
	    layout:slotPosition(5)         --> { x, y, z, lookX, lookZ }
]]

local BaseLayout = {}
BaseLayout.__index = BaseLayout

export type SlotInfo = { id: number, floor: number, side: string, index: number }
export type SlotPosition = { x: number, y: number, z: number, lookX: number, lookZ: number }

function BaseLayout.new(config: any): any
	return setmetatable({ config = config }, BaseLayout)
end

function BaseLayout:slotsPerFloor(): number
	return self.config.SlotsPerSide * 2
end

-- Lado A = primeiros 4 ids do andar; lado B = 4 seguintes
function BaseLayout:slotId(floor: number, side: string, index: number): number
	local perSide = self.config.SlotsPerSide
	assert(side == "A" or side == "B", "lado inválido: " .. tostring(side))
	assert(index >= 1 and index <= perSide, "índice inválido: " .. tostring(index))
	return (floor - 1) * perSide * 2 + (if side == "A" then 0 else perSide) + index
end

function BaseLayout:slotInfo(slotId: number): SlotInfo
	local perSide = self.config.SlotsPerSide
	local perFloor = perSide * 2
	local floor = (slotId - 1) // perFloor + 1
	local inFloor = (slotId - 1) % perFloor -- 0..7
	local side = if inFloor < perSide then "A" else "B"
	return { id = slotId, floor = floor, side = side, index = inFloor % perSide + 1 }
end

function BaseLayout:slotsForFloor(floor: number): { number }
	local list = {}
	for side = 1, 2 do
		for index = 1, self.config.SlotsPerSide do
			table.insert(list, self:slotId(floor, if side == 1 then "A" else "B", index))
		end
	end
	return list
end

-- Altura do piso do andar (topo da plataforma)
function BaseLayout:floorY(floor: number): number
	return (floor - 1) * self.config.FloorHeight + self.config.PlatformThickness
end

--[[
	Posição local do ponto onde o personagem fica (topo do pedestal) e a direção do olhar.
	Lado A (+X) olha para -X (corredor), lado B (-X) olha para +X; os dois girados
	CharacterTurnToEntrance graus para a entrada (-Z).
]]
function BaseLayout:slotPosition(slotId: number): SlotPosition
	local c = self.config
	local info = self:slotInfo(slotId)
	local sign = if info.side == "A" then 1 else -1
	local turn = math.rad(c.CharacterTurnToEntrance)
	return {
		x = sign * c.SideOffsetX,
		y = self:floorY(info.floor) + c.PedestalHeight,
		z = c.SlotFirstZ - (info.index - 1) * c.SlotSpacing,
		lookX = -sign * math.cos(turn),
		lookZ = -math.sin(turn),
	}
end

-- Lado do "poço" da rampa que sobe DO andar `fromFloor` para o próximo
function BaseLayout:rampSide(fromFloor: number): string
	return if fromFloor % 2 == 1 then "B" else "A"
end

-- Retângulo local { minX, maxX, minZ, maxZ } da rampa que sobe do andar `fromFloor`
function BaseLayout:rampRect(fromFloor: number): { minX: number, maxX: number, minZ: number, maxZ: number }
	local r = self.config.Ramp
	local sign = if self:rampSide(fromFloor) == "A" then 1 else -1
	local a, b = sign * r.InnerX, sign * r.OuterX
	return { minX = math.min(a, b), maxX = math.max(a, b), minZ = r.StartZ, maxZ = r.EndZ }
end

function BaseLayout:slotName(slotId: number): string
	return string.format("Slot%02d", slotId)
end

function BaseLayout:floorName(floor: number): string
	return string.format("Floor%02d", floor)
end

function BaseLayout.baseName(baseId: number): string
	return string.format("Base%02d", baseId)
end

return BaseLayout
