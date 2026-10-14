--!strict
--[[
	FloorLegibility (puro): o que o letreiro de uma estação mostra conforme o ANDAR do jogador.
	Bases com vários andares empilham letreiros (nome, raridade, $/s, placas MÁX, custos): olhando
	do Floor01, os do Floor02/03 viravam uma parede de texto. A regra (BaseConfig.FloorLegibility):
	    mesmo andar          -> tudo (o LOD por distância continua valendo: Detail só de perto)
	    andar vizinho (±1)   -> só a RENDA ($/s): prioridade renda > personagem > raridade/nível
	    2+ andares de distância -> nada
	Sem jogador/personagem (morto, carregando) => trata como mesmo andar (nunca esconde à toa).
	Usado pelo LodController (cliente); testado em tests/FloorLegibility.spec.luau.
]]

local FloorLegibility = {}

export type View = { detail: boolean, income: boolean, plate: boolean }

-- Distância em andares entre os pés do jogador e o piso (topo) do andar da estação.
-- Pés entre [piso - Tolerance, piso + FloorHeight - Tolerance) => mesmo andar (0).
function FloorLegibility.gap(feetY: number?, floorY: number?, config: any): number
	if feetY == nil or floorY == nil then
		return 0
	end
	local h = config.FloorHeight
	return math.abs(math.floor((feetY - floorY + config.Tolerance) / h))
end

-- level = LOD por distância (1 perto, 2 médio, 3 longe)
function FloorLegibility.view(level: number, gap: number, config: any): View
	if gap <= 0 then
		return { detail = level == 1, income = true, plate = true }
	end
	return { detail = false, income = gap <= config.IncomeMaxGap, plate = false }
end

return FloorLegibility
