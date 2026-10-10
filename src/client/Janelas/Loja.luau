-- Janelas de compra com vitórias: Escudos, Auras, Melhorias e Rebirth.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.Parent.UI)

local cores = UI.cores
local formatar = UI.formatar

local Loja = {}

-- Escudos ---------------------------------------------------------------------------

local escudosJanela, escudosLista = UI.janela("🛡️ Escudos")
Loja.Escudos = escudosJanela

local linhasEscudo: { [string]: UI.Linha } = {}
for ordem, escudo in Config.Escudos do
	local linha = UI.linha(escudosLista, ordem, escudo.Cor, escudo.Nome, `+{formatar(escudo.Bonus)} Armadura por toque`)
	linha.botao.Activated:Connect(function()
		if UI.json("Escudos")[escudo.Id] then
			UI.acao("EquiparEscudo", escudo.Id)
		else
			UI.acao("ComprarEscudo", escudo.Id)
		end
	end)
	linhasEscudo[escudo.Id] = linha
end

UI.aoAtualizar(function()
	local comprados = UI.json("Escudos")
	local equipado = UI.get("EscudoEquipado")
	local vitorias = UI.get("Vitorias")
	for _, escudo in Config.Escudos do
		local botao = linhasEscudo[escudo.Id].botao
		if equipado == escudo.Id then
			botao.Text = "Equipado"
			botao.BackgroundColor3 = cores.cinza
		elseif comprados[escudo.Id] then
			botao.Text = "Equipar"
			botao.BackgroundColor3 = cores.azul
		else
			botao.Text = `🏆 {formatar(escudo.Custo)}`
			botao.BackgroundColor3 = if vitorias >= escudo.Custo then cores.verde else cores.vermelho
		end
	end
end)

-- Auras -----------------------------------------------------------------------------

local aurasJanela, aurasLista = UI.janela("✨ Auras")
Loja.Auras = aurasJanela

local linhasAura: { [string]: UI.Linha } = {}
for ordem, aura in Config.Auras do
	local linha = UI.linha(aurasLista, ordem, aura.Cor, aura.Nome, `+{aura.Bonus * 100}% Vitórias`)
	linha.subtitulo.TextColor3 = cores.amarelo
	linha.botao.Activated:Connect(function()
		if UI.get("AuraEquipada") == aura.Id then
			UI.acao("EquiparAura", "")
		elseif UI.json("Auras")[aura.Id] then
			UI.acao("EquiparAura", aura.Id)
		else
			UI.acao("ComprarAura", aura.Id)
		end
	end)
	linhasAura[aura.Id] = linha
end

UI.aoAtualizar(function()
	local compradas = UI.json("Auras")
	local equipada = UI.get("AuraEquipada")
	local vitorias = UI.get("Vitorias")
	for _, aura in Config.Auras do
		local botao = linhasAura[aura.Id].botao
		if equipada == aura.Id then
			botao.Text = "Tirar"
			botao.BackgroundColor3 = cores.cinza
		elseif compradas[aura.Id] then
			botao.Text = "Equipar"
			botao.BackgroundColor3 = cores.azul
		else
			botao.Text = `🏆 {formatar(aura.Custo)}`
			botao.BackgroundColor3 = if vitorias >= aura.Custo then cores.verde else cores.vermelho
		end
	end
end)

-- Melhorias -------------------------------------------------------------------------

local melhoriasJanela, melhoriasLista = UI.janela("⬆️ Melhorias")
Loja.Melhorias = melhoriasJanela

local linhasMelhoria: { [string]: UI.Linha } = {}
for ordem, melhoria in Config.Melhorias do
	local linha = UI.linha(melhoriasLista, ordem, cores.verde, melhoria.Nome, "")
	linha.subtitulo.TextColor3 = Color3.fromRGB(200, 200, 200)
	linha.botao.Activated:Connect(function()
		UI.acao("ComprarMelhoria", melhoria.Id)
	end)
	linhasMelhoria[melhoria.Id] = linha
end

UI.aoAtualizar(function()
	local niveis = UI.json("Melhorias")
	local vitorias = UI.get("Vitorias")
	for _, melhoria in Config.Melhorias do
		local linha = linhasMelhoria[melhoria.Id]
		local nivel = niveis[melhoria.Id] or 0
		linha.subtitulo.Text = `Nível {nivel} / {melhoria.Max}`
		if nivel >= melhoria.Max then
			linha.botao.Text = "Máximo"
			linha.botao.BackgroundColor3 = cores.cinza
		else
			local custo = Config.custoMelhoria(melhoria.Id, nivel)
			linha.botao.Text = `🏆 {formatar(custo)}`
			linha.botao.BackgroundColor3 = if vitorias >= custo then cores.verde else cores.vermelho
		end
	end
end)

-- Rebirth ---------------------------------------------------------------------------

local rebirthJanela, rebirthLista = UI.janela("🔁 Renascimento")
Loja.Rebirth = rebirthJanela

local rebirthInfo = UI.texto("TextLabel", {
	Size = UDim2.new(1, -8, 0, 110),
	TextWrapped = true,
	ZIndex = 5,
	Parent = rebirthLista,
})
local rebirthBotao = UI.botao({
	LayoutOrder = 2,
	Size = UDim2.new(1, -8, 0, 56),
	BackgroundColor3 = cores.verde,
	Text = "Renascer",
	ZIndex = 5,
	Parent = rebirthLista,
})
rebirthBotao.Activated:Connect(function()
	UI.acao("Rebirth")
end)

UI.aoAtualizar(function()
	local rebirths = UI.get("Rebirths")
	local nivelRebirth = Config.nivelParaRebirth(rebirths)
	rebirthInfo.Text = `Rebirths: {rebirths}. Precisa de nível {nivelRebirth}. `
		.. `Zera armadura, vitórias e nível, mas você mantém escudos, pets e auras `
		.. `e ganha +{Config.BonusPorRebirth * 100}% de armadura para sempre.`
	rebirthBotao.BackgroundColor3 = if UI.get("Nivel") >= nivelRebirth then cores.verde else cores.vermelho
end)

return Loja
