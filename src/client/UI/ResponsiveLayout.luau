--!strict
--[[
	ResponsiveLayout (puro, sem Instances): geometria das janelas que REORGANIZAM o conteúdo por
	largura em vez de só encolher (Mochila e Torre). Tudo em unidades de layout (offset) dentro
	da área de conteúdo; os controllers só convertem para UDim2.fromOffset.
	Testado em tests/ResponsiveLayout.spec.luau (desktop largo, desktop menor, compacto, celular
	paisagem e retrato): nada sai da área, nada se sobrepõe, alvos de toque >= 44 unidades.

	    uiScale(viewport)                 escala global do HUD (mesma conta do UIKit)
	    fitWindow(viewport, max, min)     tamanho da janela + "boost" de leitura em telas pequenas
	    backpackHeader(w) / backpackFooter(w) / backpackBody(w, h, footer)
	    towerHeader(w)
]]

export type Rect = { x: number, y: number, w: number, h: number }

local ResponsiveLayout = {}

ResponsiveLayout.Gap = 6
ResponsiveLayout.Row = 44 -- altura mínima de um alvo de toque (unidades de layout)
ResponsiveLayout.Reference = { x = 1280, y = 720 }
-- escala física mínima das janelas em telas pequenas (44 unidades ~ 33 px no celular)
ResponsiveLayout.MinPhysicalScale = 0.75

local function rect(x: number, y: number, w: number, h: number): Rect
	return { x = math.floor(x + 0.5), y = math.floor(y + 0.5), w = math.floor(w + 0.5), h = math.floor(h + 0.5) }
end

function ResponsiveLayout.uiScale(vx: number, vy: number): number
	local ref = ResponsiveLayout.Reference
	return math.clamp(math.min(vx / ref.x, vy / ref.y), 0.45, 1.25)
end

--[[
	Tamanho da janela para a tela: cabe no viewport com margem e, em telas pequenas, recebe um
	"boost" (UIScale do painel) para que a escala física fique >= MinPhysicalScale — o conteúdo
	é REORGANIZADO para a largura resultante (modos compacto/retrato), não só reduzido.
]]
function ResponsiveLayout.fitWindow(vx: number, vy: number, maxW: number, maxH: number, minW: number?, minH: number?)
	local scale = ResponsiveLayout.uiScale(vx, vy)
	local boost = math.clamp(ResponsiveLayout.MinPhysicalScale / scale, 1, 2)
	local effective = scale * boost
	local margin = 16
	local w = math.clamp(math.floor((vx - margin) / effective), minW or 300, maxW)
	local h = math.clamp(math.floor((vy - margin) / effective), minH or 280, maxH)
	return { w = w, h = h, boost = boost, scale = scale, effective = effective }
end

------------------------------------------------------------------------------------
-- MOCHILA

ResponsiveLayout.BackpackWide = 1060
ResponsiveLayout.BackpackCompact = 600

--[[
	Cabeçalho da MOCHILA (3 áreas):
	    1 título + capacidade · 2 filtros + busca · 3 ações (EQUIPAR MELHORES, 🗑 LIXEIRA)
	wide     uma linha:   [1][2................][3]
	compact  duas linhas: [1 ........... 3] / [2 (filtros + busca)]
	portrait duas linhas: [1 ..... ⚡ 🗑] / [filtro (cicla) | busca]
]]
function ResponsiveLayout.backpackHeader(width: number)
	local G, R = ResponsiveLayout.Gap, ResponsiveLayout.Row
	local mode = if width >= ResponsiveLayout.BackpackWide then "wide" elseif width >= ResponsiveLayout.BackpackCompact then "compact" else "portrait"
	local out: any = { mode = mode, filters = {} }
	local titleW = if mode == "portrait" then 96 else 120
	local capW = if mode == "portrait" then 76 else 86
	out.title = rect(0, 0, titleW, R)
	out.capacity = rect(titleW + G, 0, capW, R)
	local trashW = 52
	out.trash = rect(width - trashW, 0, trashW, R)
	local bestW = if mode == "portrait" then 52 else 190
	out.equipBest = rect(width - trashW - G - bestW, 0, bestW, R)
	out.equipBestIconOnly = mode == "portrait"
	if mode == "wide" then
		local left = titleW + G + capW + 12
		local right = out.equipBest.x - 12
		local area = right - left
		local searchW = math.clamp(math.floor(area * 0.22), 110, 170)
		local bw = math.clamp(math.floor((area - searchW - G * 5) / 5), 64, 100)
		for i = 1, 5 do
			out.filters[i] = rect(left + (i - 1) * (bw + G), 0, bw, R)
		end
		out.search = rect(left + 5 * (bw + G), 0, math.min(searchW, right - (left + 5 * (bw + G))), R)
		out.height = R
	elseif mode == "compact" then
		local y = R + G
		local searchW = math.clamp(math.floor(width * 0.24), 120, 180)
		local bw = math.floor((width - searchW - G * 5) / 5)
		for i = 1, 5 do
			out.filters[i] = rect((i - 1) * (bw + G), y, bw, R)
		end
		out.search = rect(5 * (bw + G), y, width - 5 * (bw + G), R)
		out.height = y + R
	else
		local y = R + G
		local half = math.floor((width - G) / 2)
		out.filterCycle = rect(0, y, half, R)
		out.search = rect(half + G, y, width - half - G, R)
		out.height = y + R
	end
	return out
end

-- Rodapé do MODO VENDA: info (X selecionados · Você receberá) + [DUPLICATAS] [CANCELAR] [VENDER]
function ResponsiveLayout.backpackFooter(width: number)
	local G, R = ResponsiveLayout.Gap, ResponsiveLayout.Row
	local out: any = {}
	if width >= 760 then
		local sellW, cancelW, dupesW = 230, 130, 210
		local x = width - sellW
		out.sell = rect(x, 6, sellW, R)
		x -= G + cancelW
		out.cancel = rect(x, 6, cancelW, R)
		x -= G + dupesW
		out.dupes = rect(x, 6, dupesW, R)
		out.info = rect(0, 6, x - 10, R)
		out.height = R + 12
		out.mode = "row"
	else
		out.info = rect(0, 4, width, 26)
		local y = 4 + 26 + G
		local free = width - G * 2
		local sellW = math.floor(free * 0.4)
		local dupesW = math.floor(free * 0.35)
		local cancelW = free - sellW - dupesW
		out.dupes = rect(0, y, dupesW, R)
		out.cancel = rect(dupesW + G, y, cancelW, R)
		out.sell = rect(dupesW + G + cancelW + G, y, sellW, R)
		out.height = y + R + 4
		out.mode = "stacked"
	end
	return out
end

-- Corpo: grade + painel de detalhes (ao lado no largo; sobreposto no estreito)
function ResponsiveLayout.backpackBody(width: number, height: number, headerH: number, footerH: number?)
	local top = headerH + 10
	local bottom = height - (if footerH then footerH + 8 else 0)
	local out: any = {}
	if width >= 760 then
		out.grid = rect(0, top, width - 280, bottom - top)
		out.detail = rect(width - 268, top, 268, bottom - top)
		out.detailOverlay = false
	else
		out.grid = rect(0, top, width, bottom - top)
		local h = math.min(bottom - top, 430)
		out.detail = rect(0, bottom - h, width, h)
		out.detailOverlay = true
	end
	-- colunas da grade (cards 112x138): pelo menos 2
	out.columns = math.max(2, math.floor((out.grid.w - 8 + 8) / (112 + 8)))
	return out
end

------------------------------------------------------------------------------------
-- TORRE

ResponsiveLayout.TowerWide = 700

--[[
	Cabeçalho da TORRE (duas linhas, AUTO e TIME AUTO sempre separados):
	    linha 1: "Time automático ⚔ 1.2K" ........................ [AUTO: ON]
	    linha 2: [chip][chip][chip][chip][chip] ............... [TIME AUTO]
	estreito: os chips encolhem (mín. 40) e os botões mantêm >= 44 de altura.
]]
function ResponsiveLayout.towerHeader(width: number, chips: number)
	local G, R = ResponsiveLayout.Gap, ResponsiveLayout.Row
	local wide = width >= ResponsiveLayout.TowerWide
	local out: any = { mode = if wide then "wide" else "compact", chips = {} }
	local autoW = if wide then 150 else 128
	local teamW = if wide then 170 else 138
	out.auto = rect(width - autoW, 0, autoW, R)
	out.label = rect(0, 0, width - autoW - 12, R)
	local y = R + G
	local n = math.max(chips, 1)
	local function chipSize(avail: number): number
		return math.floor((avail - G * (n - 1)) / n)
	end
	if chipSize(width - teamW - 12) >= 40 then
		-- linha 2: chips + TIME AUTO à direita
		out.autoTeam = rect(width - teamW, y, teamW, R)
		local size = math.min(chipSize(width - teamW - 12), R)
		for i = 1, chips do
			out.chips[i] = rect((i - 1) * (size + G), y + (R - size) / 2, size, size)
		end
		out.height = y + R
	else
		-- muito estreito: chips na linha 2 inteira, TIME AUTO numa linha 3 (reorganiza, não encolhe)
		out.mode = "stacked"
		local size = math.clamp(chipSize(width), 40, R)
		for i = 1, chips do
			out.chips[i] = rect((i - 1) * (size + G), y + (R - size) / 2, size, size)
		end
		local y3 = y + R + G
		out.autoTeam = rect(width - teamW, y3, teamW, R)
		out.height = y3 + R
		return out
	end
	return out
end

------------------------------------------------------------------------------------
-- TOOLTIP: lado escolhido para NÃO cobrir o alvo nem os controles críticos ("avoid"),
-- sempre dentro da tela. Ordem: abaixo, acima, direita, esquerda; se todos cobrirem algo,
-- fica o que cobre menos área crítica (preso à tela).

function ResponsiveLayout.placeTooltip(target: Rect, w: number, h: number, screenW: number, screenH: number, avoid: { Rect }?): (Rect, string)
	local G = ResponsiveLayout.Gap
	local function clampRect(x: number, y: number): Rect
		return rect(math.clamp(x, 4, math.max(4, screenW - w - 4)), math.clamp(y, 4, math.max(4, screenH - h - 4)), w, h)
	end
	local cx = target.x + target.w / 2 - w / 2
	local cy = target.y + target.h / 2 - h / 2
	local below, above = target.y + target.h + G, target.y - h - G
	local options: { { side: string, r: Rect } } = {
		{ side = "below", r = clampRect(cx, below) },
		{ side = "above", r = clampRect(cx, above) },
		{ side = "right", r = clampRect(target.x + target.w + G, cy) },
		{ side = "left", r = clampRect(target.x - w - G, cy) },
		-- alinhados à borda do alvo (fogem de vizinhos em linha)
		{ side = "above", r = clampRect(target.x + target.w - w, above) },
		{ side = "above", r = clampRect(target.x, above) },
		{ side = "below", r = clampRect(target.x + target.w - w, below) },
		{ side = "below", r = clampRect(target.x, below) },
	}
	local function cost(r: Rect): number
		local total = 0
		for _, a in { target, table.unpack(avoid or {}) } do
			if ResponsiveLayout.overlaps(r, a) then
				local ix = math.min(r.x + r.w, a.x + a.w) - math.max(r.x, a.x)
				local iy = math.min(r.y + r.h, a.y + a.h) - math.max(r.y, a.y)
				total += ix * iy
			end
		end
		return total
	end
	local best, bestSide, bestCost = options[1].r, options[1].side, math.huge
	for _, option in options do
		local c = cost(option.r)
		if c < bestCost then
			best, bestSide, bestCost = option.r, option.side, c
		end
		if c == 0 then
			break
		end
	end
	return best, bestSide
end

-- Utilitário dos testes/DEV: dois retângulos se sobrepõem?
function ResponsiveLayout.overlaps(a: Rect, b: Rect): boolean
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

return ResponsiveLayout
