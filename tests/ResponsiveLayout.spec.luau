-- Layout responsivo (Mochila/Torre/tooltip): reorganiza por largura, nada fora/sobreposto
local T = require("./TestLib")
local L = require("../src/client/UI/ResponsiveLayout")
local describe, it, expect = T.describe, T.it, T.expect

-- aparelhos reais (px): desktop largo, desktop menor, notebook, tablet retrato, celular paisagem/retrato
local DEVICES = {
	{ "desktop 1920x1080", 1920, 1080 },
	{ "desktop 1366x768", 1366, 768 },
	{ "desktop menor 1024x640", 1024, 640 },
	{ "tablet retrato 768x1024", 768, 1024 },
	{ "celular paisagem 844x390", 844, 390 },
	{ "celular paisagem 667x375", 667, 375 },
	{ "celular retrato 390x844", 390, 844 },
	{ "celular retrato 360x640", 360, 640 },
}
local WIDTHS = { 1400, 1200, 1136, 1060, 1000, 900, 856, 760, 700, 640, 600, 560, 480, 420, 360, 320, 300 }

local function inside(r: any, w: number, h: number): boolean
	return r.x >= 0 and r.y >= 0 and r.x + r.w <= w and r.y + r.h <= h
end
local function noOverlap(rects: { any }): boolean
	for i = 1, #rects do
		for j = i + 1, #rects do
			if L.overlaps(rects[i], rects[j]) then
				return false
			end
		end
	end
	return true
end
local function headerRects(hd: any): { any }
	local list = { hd.title, hd.capacity, hd.equipBest, hd.trash, hd.search }
	for _, f in hd.filters do
		table.insert(list, f)
	end
	if hd.filterCycle then
		table.insert(list, hd.filterCycle)
	end
	return list
end

describe("Responsivo: janela cabe na tela e mantém alvo de toque", function()
	it("todas as telas: janela dentro do viewport e escala física >= 0.75 (44 unidades >= 33 px)", function()
		for _, d in DEVICES do
			local fit = L.fitWindow(d[2], d[3], 1180, 640, 320, 300)
			expect(fit.w * fit.effective <= d[2]).toBeTruthy()
			expect(fit.h * fit.effective <= d[3] or fit.h == 300).toBeTruthy()
			expect(fit.effective >= 0.75 - 1e-9).toBeTruthy()
			expect(L.Row * fit.effective >= 33 - 1e-6).toBeTruthy()
		end
	end)

	it("os três modos da Mochila aparecem nos aparelhos reais (wide/compact/portrait)", function()
		local seen = {}
		for _, d in DEVICES do
			local fit = L.fitWindow(d[2], d[3], 1180, 640, 320, 300)
			seen[L.backpackHeader(fit.w - 44).mode] = true
		end
		expect(seen.wide and seen.compact and seen.portrait).toBeTruthy()
	end)
end)

describe("Responsivo: cabeçalho da MOCHILA", function()
	it("nenhuma área sai da largura nem se sobrepõe (17 larguras)", function()
		for _, w in WIDTHS do
			local hd = L.backpackHeader(w)
			for _, r in headerRects(hd) do
				expect(inside(r, w, hd.height)).toBeTruthy()
				expect(r.h >= L.Row).toBeTruthy()
				expect(r.w >= 44).toBeTruthy()
			end
			expect(noOverlap(headerRects(hd))).toBeTruthy()
		end
	end)

	it("LIXEIRA sempre visível e separada de EQUIPAR MELHORES; filtros >= 64 de largura", function()
		for _, w in WIDTHS do
			local hd = L.backpackHeader(w)
			expect(hd.trash.x + hd.trash.w).toBe(w)
			expect(hd.trash.x - (hd.equipBest.x + hd.equipBest.w) >= L.Gap).toBeTruthy()
			for _, f in hd.filters do
				expect(f.w >= 64).toBeTruthy()
			end
		end
		expect(L.backpackHeader(1200).mode).toBe("wide")
		expect(L.backpackHeader(800).mode).toBe("compact")
		expect(L.backpackHeader(420).mode).toBe("portrait")
		expect(L.backpackHeader(420).filterCycle ~= nil).toBeTruthy()
	end)
end)

describe("Responsivo: rodapé do MODO VENDA e corpo", function()
	it("rodapé: botões e info dentro, sem sobreposição, alvos >= 44", function()
		for _, w in WIDTHS do
			local ft = L.backpackFooter(w)
			local rects = { ft.info, ft.dupes, ft.cancel, ft.sell }
			for _, r in rects do
				expect(inside(r, w, ft.height)).toBeTruthy()
			end
			for _, r in { ft.dupes, ft.cancel, ft.sell } do
				expect(r.h >= L.Row).toBeTruthy()
			end
			expect(noOverlap(rects)).toBeTruthy()
		end
	end)

	it("corpo: grade + detalhes sem sobreposição no largo; grade >= 2 colunas; rodapé não cobre a grade", function()
		for _, w in WIDTHS do
			local hd = L.backpackHeader(w)
			local ft = L.backpackFooter(w)
			local body = L.backpackBody(w, 520, hd.height, ft.height)
			expect(body.grid.y >= hd.height).toBeTruthy()
			expect(body.grid.y + body.grid.h <= 520 - ft.height).toBeTruthy()
			expect(inside(body.grid, w, 520)).toBeTruthy()
			expect(inside(body.detail, w, 520)).toBeTruthy()
			if not body.detailOverlay then
				expect(L.overlaps(body.grid, body.detail)).toBe(false)
			end
			expect(body.columns >= 2).toBeTruthy()
		end
	end)
end)

describe("Responsivo: cabeçalho da TORRE", function()
	it("AUTO e TIME AUTO em linhas diferentes, sem sobreposição com rótulo e chips", function()
		for _, w in WIDTHS do
			for chips = 0, 5 do
				local th = L.towerHeader(w, chips)
				local rects = { th.label, th.auto, th.autoTeam }
				for _, c in th.chips do
					table.insert(rects, c)
					expect(c.w >= 40).toBeTruthy()
				end
				for _, r in rects do
					expect(inside(r, w, th.height)).toBeTruthy()
				end
				expect(noOverlap(rects)).toBeTruthy()
				expect(th.auto.y ~= th.autoTeam.y).toBeTruthy()
				expect(th.auto.h >= L.Row and th.autoTeam.h >= L.Row).toBeTruthy()
			end
		end
	end)
end)

describe("Responsivo: tooltip inteligente", function()
	it("sempre dentro da tela e sem cobrir o alvo nem controles críticos quando há espaço", function()
		local screenW, screenH = 1280, 720
		-- cabeçalho da Torre na posição real (janela centrada: conteúdo começa em ~(100, 150))
		local raw = L.towerHeader(1080, 5)
		local function at(r)
			return { x = r.x + 100, y = r.y + 150, w = r.w, h = r.h }
		end
		local th = { auto = at(raw.auto), autoTeam = at(raw.autoTeam), chips = { at(raw.chips[1]), at(raw.chips[5]) } }
		local critical = { th.auto, th.autoTeam }
		for _, target in { th.chips[1], th.chips[2], th.auto, th.autoTeam, { x = 0, y = 0, w = 44, h = 44 }, { x = screenW - 44, y = screenH - 44, w = 44, h = 44 } } do
			local r = L.placeTooltip(target, 220, 56, screenW, screenH, critical)
			expect(inside(r, screenW, screenH)).toBeTruthy()
			expect(L.overlaps(r, target)).toBe(false)
			for _, c in critical do
				if c ~= target then
					expect(L.overlaps(r, c)).toBe(false)
				end
			end
		end
		-- canto inferior: não cabe abaixo -> vai para cima
		local _, side = L.placeTooltip({ x = 500, y = screenH - 50, w = 44, h = 44 }, 220, 56, screenW, screenH, {})
		expect(side).toBe("above")
	end)
end)

return true
