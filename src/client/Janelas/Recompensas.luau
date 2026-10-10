-- Recompensa diária, presentes por tempo de jogo, poções e boosts com Robux.
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.Parent.UI)

local cores = UI.cores

local Recompensas = {}

-- Diária + presentes ------------------------------------------------------------------

local janela, lista = UI.janela("🎁 Recompensas")
Recompensas.Janela = janela

local diaria = UI.linha(lista, 0, cores.amarelo, "Recompensa diária", "")
diaria.subtitulo.TextColor3 = Color3.fromRGB(220, 220, 220)
diaria.botao.Activated:Connect(function()
	UI.acao("ColetarDiaria")
end)

local linhasPresente: { UI.Linha } = {}
for indice, presente in Config.Presentes do
	local linha = UI.linha(
		lista,
		indice,
		cores.roxo,
		Config.descreverRecompensa(presente.Recompensa),
		`Jogue {presente.Minutos} min`
	)
	linha.subtitulo.TextColor3 = Color3.fromRGB(220, 220, 220)
	linha.botao.Activated:Connect(function()
		UI.acao("ColetarPresente", indice)
	end)
	linhasPresente[indice] = linha
end

-- Quantos presentes estão prontos para coletar (para o aviso no botão do menu)
function Recompensas.prontos(): number
	local total = 0
	local passado = UI.agora() - (UI.player:GetAttribute("InicioSessao") or UI.agora())
	local coletados = UI.json("PresentesColetados")
	for indice, presente in Config.Presentes do
		if not coletados[tostring(indice)] and passado >= presente.Minutos * 60 then
			total += 1
		end
	end
	if UI.agora() - UI.get("UltimaDiaria") >= 20 * 3600 then
		total += 1
	end
	return total
end

local function atualizarRecompensas()
	local agora = UI.agora()
	local ultima = UI.get("UltimaDiaria")
	local sequencia = UI.get("SequenciaDiaria")
	if agora - ultima > 48 * 3600 then
		sequencia = 0
	end
	local proxima = Config.Diarias[sequencia % #Config.Diarias + 1]
	diaria.titulo.Text = `Dia {sequencia % #Config.Diarias + 1}: {Config.descreverRecompensa(proxima)}`
	local falta = ultima + 20 * 3600 - agora
	if falta <= 0 then
		diaria.subtitulo.Text = "Pronta para coletar!"
		diaria.botao.Text = "Coletar"
		diaria.botao.BackgroundColor3 = cores.verde
	else
		diaria.subtitulo.Text = `Volte em {UI.formatarTempo(falta)}`
		diaria.botao.Text = "⏳"
		diaria.botao.BackgroundColor3 = cores.cinza
	end

	local passado = agora - (UI.player:GetAttribute("InicioSessao") or agora)
	-- O JSON transforma as chaves numéricas em texto
	local coletados = UI.json("PresentesColetados")
	for indice, linha in linhasPresente do
		local presente = Config.Presentes[indice]
		local faltaPresente = presente.Minutos * 60 - passado
		if coletados[tostring(indice)] then
			linha.botao.Text = "✅"
			linha.botao.BackgroundColor3 = cores.cinza
		elseif faltaPresente <= 0 then
			linha.botao.Text = "Coletar"
			linha.botao.BackgroundColor3 = cores.verde
		else
			linha.botao.Text = UI.formatarTempo(faltaPresente)
			linha.botao.BackgroundColor3 = cores.cinza
		end
	end
end

UI.aoAtualizar(atualizarRecompensas)
task.spawn(function()
	while true do
		task.wait(1)
		if janela.Visible then
			atualizarRecompensas()
		end
	end
end)

-- Poções e boosts -----------------------------------------------------------------------

local pocoesJanela, pocoesLista = UI.janela("🧪 Poções e Boosts")
Recompensas.Pocoes = pocoesJanela

local linhasPocao: { [string]: UI.Linha } = {}
local ordem = 0
for id, pocao in Config.Pocoes do
	ordem += 1
	local descricao = if id == "Sorte" then "Mais chance de pets raros" else `x{pocao.Mult} {id}`
	local linha = UI.linha(pocoesLista, ordem, pocao.Cor, pocao.Nome, `{descricao} · {pocao.Minutos} min`)
	linha.subtitulo.TextColor3 = Color3.fromRGB(220, 220, 220)
	linha.botao.Activated:Connect(function()
		UI.acao("UsarPocao", id)
	end)
	linhasPocao[id] = linha
end

for i, produto in Config.Produtos do
	local linha = UI.linha(pocoesLista, 100 + i, cores.vermelho, produto.Nome, "Compra com Robux")
	linha.subtitulo.TextColor3 = cores.amarelo
	linha.botao.Text = "💎 Comprar"
	linha.botao.BackgroundColor3 = cores.verde
	linha.botao.Activated:Connect(function()
		if produto.Id == 0 then
			UI.notificar(`Configure o ID do produto "{produto.Nome}" no Config.luau`)
		else
			MarketplaceService:PromptProductPurchase(UI.player, produto.Id)
		end
	end)
end

UI.aoAtualizar(function()
	local qtd = UI.json("Pocoes")
	local boosts = UI.json("Boosts")
	local agora = UI.agora()
	for id, linha in linhasPocao do
		local restante = (boosts[id] or 0) - agora
		local ativa = if restante > 0 then ` · ativa {UI.formatarTempo(restante)}` else ""
		linha.titulo.Text = `{Config.Pocoes[id].Nome} (x{qtd[id] or 0}){ativa}`
		linha.botao.Text = "Usar"
		linha.botao.BackgroundColor3 = if (qtd[id] or 0) > 0 then cores.verde else cores.cinza
	end
end)

-- Texto curto com os boosts ativos (mostrado no HUD)
function Recompensas.boostsAtivos(): string
	local partes = {}
	local agora = UI.agora()
	local boosts = UI.json("Boosts")
	for id in Config.Pocoes do
		local restante = (boosts[id] or 0) - agora
		if restante > 0 then
			table.insert(partes, `🧪{id} {UI.formatarTempo(restante)}`)
		end
	end
	local compradoAte = UI.get("BoostCompradoAte")
	if compradoAte > agora then
		table.insert(partes, `⚡x{UI.get("BoostCompradoMult")} {UI.formatarTempo(compradoAte - agora)}`)
	end
	return table.concat(partes, "  ")
end

return Recompensas
