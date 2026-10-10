-- Lista de mundos: liberar o próximo e teleportar para os já liberados.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.Parent.UI)

local cores = UI.cores

local Mundos = {}

local janela, lista = UI.janela("🌍 Mundos")
Mundos.Janela = janela

local linhas: { UI.Linha } = {}
for indice, mundo in Config.Mundos do
	local linha = UI.linha(
		lista,
		indice,
		mundo.Cores[3],
		mundo.Nome,
		`Paredes x{UI.formatar(mundo.MultVida)} · Vitórias x{UI.formatar(mundo.MultVitorias)}`
	)
	linha.subtitulo.TextColor3 = Color3.fromRGB(220, 220, 220)
	linha.botao.Activated:Connect(function()
		if indice <= UI.get("MundoMax") then
			UI.acao("IrMundo", indice)
		else
			UI.acao("ComprarMundo", indice)
		end
	end)
	linhas[indice] = linha
end

UI.aoAtualizar(function()
	local atual = UI.get("Mundo")
	local maximo = UI.get("MundoMax")
	local vitorias = UI.get("Vitorias")
	for indice, linha in linhas do
		local mundo = Config.Mundos[indice]
		if indice == atual then
			linha.botao.Text = "Você está aqui"
			linha.botao.BackgroundColor3 = cores.cinza
		elseif indice <= maximo then
			linha.botao.Text = "Ir"
			linha.botao.BackgroundColor3 = cores.azul
		elseif indice == maximo + 1 then
			linha.botao.Text = `🏆 {UI.formatar(mundo.Custo)}`
			linha.botao.BackgroundColor3 = if vitorias >= mundo.Custo then cores.verde else cores.vermelho
		else
			linha.botao.Text = "🔒"
			linha.botao.BackgroundColor3 = cores.cinza
		end
	end
end)

return Mundos
