-- HUD principal: botão TOQUE!, nível, tutorial, autoclick, gamepasses e menu das janelas.
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.UI)
local Loja = require(script.Parent.Janelas.Loja)
local Pets = require(script.Parent.Janelas.Pets)
local Mundos = require(script.Parent.Janelas.Mundos)
local Recompensas = require(script.Parent.Janelas.Recompensas)

local player = UI.player
local cores = UI.cores
local formatar = UI.formatar
local get = UI.get
local gui = UI.gui

local function comprarPasse(nome: string)
	local passe = Config.Gamepasses[nome]
	if player:GetAttribute(`Passe_{nome}`) then
		return
	end
	if passe.Id == 0 then
		UI.notificar(`Configure o ID do gamepass "{passe.Nome}" no Config.luau`)
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, passe.Id)
end

-- Topo esquerdo: vitórias, rebirths e boosts ativos ---------------------------------

local stats = UI.create("Frame", {
	Position = UDim2.new(0, 16, 0, 16),
	Size = UDim2.fromOffset(260, 120),
	BackgroundTransparency = 1,
	Parent = gui,
}, { UI.create("UIListLayout", { Padding = UDim.new(0, 2) }) })

local vitoriasLabel = UI.texto("TextLabel", {
	Size = UDim2.new(0.7, 0, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = stats,
})
local rebirthsLabel = UI.texto("TextLabel", {
	Size = UDim2.new(0.7, 0, 0, 36),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = stats,
})
local boostsLabel = UI.texto("TextLabel", {
	Size = UDim2.new(1, 0, 0, 22),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(150, 255, 150),
	Parent = stats,
})

-- Tutorial ------------------------------------------------------------------------------

local tutorial = UI.create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0.4, 0, 0, 110),
	BackgroundColor3 = Color3.fromRGB(30, 30, 30),
	Parent = gui,
}, { UI.corner(), UI.borda(4) })

local tutorialTitulo = UI.texto("TextLabel", {
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundColor3 = Color3.fromRGB(170, 120, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = tutorial,
})
UI.corner().Parent = tutorialTitulo

local tutorialTexto = UI.texto("TextLabel", {
	Position = UDim2.new(0, 8, 0, 38),
	Size = UDim2.new(1, -16, 0, 40),
	Parent = tutorial,
})
local tutorialProgresso = UI.texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 6),
	Size = UDim2.new(0.8, 0, 0, 40),
	Parent = tutorial,
})

-- Botão TOQUE! ----------------------------------------------------------------------------

local toqueLabel = UI.texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.7, 0, 0.45, -72),
	Size = UDim2.fromOffset(200, 50),
	TextColor3 = cores.amarelo,
	Text = "TOQUE!",
	Parent = gui,
})

local TAMANHO_TOQUE = UDim2.fromOffset(130, 130)
local toque = UI.create("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.7, 0, 0.45, 0),
	Size = TAMANHO_TOQUE,
	BackgroundColor3 = Color3.new(1, 1, 1),
	Text = "👆",
	TextScaled = true,
	Parent = gui,
}, {
	UI.corner(UDim.new(1, 0)),
	UI.create("UIStroke", { Thickness = 8, Color = cores.amarelo, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})

local function mostrarGanho()
	local ganho = UI.texto("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = toque.Position + UDim2.fromOffset(math.random(-60, 60), -40),
		Size = UDim2.fromOffset(120, 36),
		TextColor3 = cores.amarelo,
		Text = `+{UI.formatarDecimal(get("GanhoPorClique") or 1)} 🛡️`,
		Parent = gui,
	})
	TweenService:Create(ganho, TweenInfo.new(0.8), {
		Position = ganho.Position - UDim2.fromOffset(0, 80),
		TextTransparency = 1,
	}):Play()
	task.delay(0.8, ganho.Destroy, ganho)
end

local function clicar()
	UI.acao("Click")
	mostrarGanho()
end

toque.Activated:Connect(function()
	clicar()
	toque.Size = TAMANHO_TOQUE - UDim2.fromOffset(16, 16)
	TweenService:Create(toque, TweenInfo.new(0.12), { Size = TAMANHO_TOQUE }):Play()
end)

-- Barra de baixo: armadura, nível e boosts de Robux ---------------------------------------

local armaduraLabel = UI.texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -136),
	Size = UDim2.fromOffset(320, 40),
	Parent = gui,
})

local barra = UI.create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -72),
	Size = UDim2.fromOffset(340, 60),
	BackgroundColor3 = cores.marrom,
	ClipsDescendants = true,
	Parent = gui,
}, { UI.corner(), UI.borda(4) })

local barraXP = UI.create("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(150, 110, 30),
	BorderSizePixel = 0,
	Parent = barra,
}, { UI.corner() })

local nivelLabel = UI.texto("TextLabel", {
	Position = UDim2.new(0, 12, 0, 6),
	Size = UDim2.new(0.5, -12, 1, -12),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = barra,
})
local xpLabel = UI.texto("TextLabel", {
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0.5, -12, 1, -28),
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = barra,
})

local boostsRobux = UI.create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.fromOffset(340, 52),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	UI.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
})
for i, produto in Config.Produtos do
	local b = UI.botao({
		Size = UDim2.new(1 / 3, -6, 1, 0),
		BackgroundColor3 = if i == 1 then cores.amarelo elseif i == 2 then Color3.fromRGB(230, 110, 40) else cores.vermelho,
		Text = `🛡️ x{produto.Mult}`,
		Parent = boostsRobux,
	})
	b.Activated:Connect(function()
		if produto.Id == 0 then
			UI.notificar(`Configure o ID do produto "{produto.Nome}" no Config.luau`)
		else
			MarketplaceService:PromptProductPurchase(player, produto.Id)
		end
	end)
end

local infoEsquerda = UI.create("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(0.5, -180, 1, -72),
	Size = UDim2.fromOffset(190, 84),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	UI.create("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}),
})

local function infoLinha(): TextLabel
	return UI.texto("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = infoEsquerda,
	})
end
local velocidadeLabel = infoLinha()
local multArmaduraLabel = infoLinha()
local multVitoriasLabel = infoLinha()

-- Botões automáticos (à direita da barra) ------------------------------------------------

local autoBotoes = UI.create("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 180, 1, -12),
	Size = UDim2.fromOffset(180, 170),
	BackgroundTransparency = 1,
	Parent = gui,
}, { UI.create("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom }) })

local function autoBotao(cor: Color3): TextButton
	return UI.botao({
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = cor,
		TextColor3 = cores.vermelho,
		Parent = autoBotoes,
	})
end
local vitoriasAutoBotao = autoBotao(cores.vermelho)
vitoriasAutoBotao.TextColor3 = Color3.new(1, 1, 1)
local autoOPBotao = autoBotao(cores.amarelo)
local autoClickBotao = autoBotao(Color3.new(1, 1, 1))

local autoClickLigado = false

task.spawn(function()
	while true do
		task.wait(
			if player:GetAttribute("Passe_AutoClickOP") then Config.AutoClickOPIntervalo else Config.AutoClickIntervalo
		)
		if autoClickLigado then
			clicar()
		end
	end
end)

autoClickBotao.Activated:Connect(function()
	autoClickLigado = not autoClickLigado
	UI.atualizarTudo()
end)
autoOPBotao.Activated:Connect(function()
	comprarPasse("AutoClickOP")
end)
vitoriasAutoBotao.Activated:Connect(function()
	UI.acao("AlternarVitoriasAuto")
end)

-- Gamepasses (coluna da direita) ----------------------------------------------------------

local passesColuna = UI.create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, -20),
	Size = UDim2.fromOffset(180, 320),
	BackgroundTransparency = 1,
	Parent = gui,
}, { UI.create("UIListLayout", { Padding = UDim.new(0, 8) }) })

local passeBotoes: { [string]: TextButton } = {}
for _, info in {
	{ "DobroArmadura", cores.vermelho },
	{ "DobroVitorias", cores.amarelo },
	{ "Velocidade", cores.azul },
	{ "PetsExtra", cores.roxo },
} do
	local nome, cor = info[1], info[2]
	local b = UI.botao({ Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = cor, Parent = passesColuna })
	b.Activated:Connect(function()
		comprarPasse(nome)
	end)
	passeBotoes[nome] = b
end

-- Menu da esquerda (grade 2 colunas) ------------------------------------------------------

local menu = UI.create("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 30),
	Size = UDim2.fromOffset(196, 360),
	BackgroundTransparency = 1,
	Parent = gui,
}, { UI.create("UIGridLayout", { CellSize = UDim2.fromOffset(92, 64), CellPadding = UDim2.fromOffset(10, 8) }) })

local recompensasBotao: TextButton
for ordem, item in {
	{ "🛒 Escudos", cores.azul, Loja.Escudos },
	{ "🐾 Pets", Color3.fromRGB(240, 140, 60), Pets.Inventario },
	{ "🔮 Fusão", cores.roxo, Pets.Fusao },
	{ "🔁 Rebirth", cores.verde, Loja.Rebirth },
	{ "⬆️ Melhorias", Color3.fromRGB(40, 170, 120), Loja.Melhorias },
	{ "✨ Auras", Color3.fromRGB(230, 60, 90), Loja.Auras },
	{ "🌍 Mundos", Color3.fromRGB(60, 120, 200), Mundos.Janela },
	{ "🧪 Poções", Color3.fromRGB(200, 60, 160), Recompensas.Pocoes },
	{ "🎁 Prêmios", cores.amarelo, Recompensas.Janela },
} do
	local texto, cor, janela = item[1], item[2], item[3]
	local b = UI.botao({ LayoutOrder = ordem, BackgroundColor3 = cor, Text = texto, Parent = menu })
	b.Activated:Connect(function()
		UI.abrir(janela)
	end)
	if janela == Recompensas.Janela then
		recompensasBotao = b
	end
end

-- Aviso vermelho no botão de prêmios quando há algo para coletar
local aviso = UI.texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = cores.vermelho,
	Text = "!",
	Visible = false,
	ZIndex = 3,
	Parent = recompensasBotao,
})
UI.corner(UDim.new(1, 0)).Parent = aviso

-- Atualização do HUD ------------------------------------------------------------------------

local nivelAnterior = get("Nivel")

local function atualizarHUD()
	local nivel = get("Nivel")
	local rebirths = get("Rebirths")

	if nivel > nivelAnterior then
		UI.notificar(`⬆️ Nível {nivel}!`)
	end
	nivelAnterior = nivel

	vitoriasLabel.Text = `🏆 {formatar(get("Vitorias"))}`
	rebirthsLabel.Text = `🔁 {rebirths}`
	boostsLabel.Text = Recompensas.boostsAtivos()
	armaduraLabel.Text = `Armadura: {formatar(get("Armadura"))}`

	local necessario = Config.xpParaNivel(nivel)
	nivelLabel.Text = `Nível {nivel}`
	xpLabel.Text = `{formatar(get("XP"))} / {formatar(necessario)}`
	barraXP.Size = UDim2.fromScale(math.clamp(get("XP") / necessario, 0, 1), 1)

	local melhorias = UI.json("Melhorias")
	local velocidade = Config.VelocidadeBase
		+ (if player:GetAttribute("Passe_Velocidade") then Config.VelocidadeGamepass else 0)
		+ (melhorias.Velocidade or 0) * 2
	velocidadeLabel.Text = `👟 Velocidade: {velocidade}`
	multArmaduraLabel.Text = `🛡️ x{string.format("%.2f", get("MultArmadura") or 1)} Armadura`
	multVitoriasLabel.Text = `🏆 x{string.format("%.2f", get("MultVitorias") or 1)} Vitórias`

	autoClickBotao.Text = if autoClickLigado then "Clique Automático\nAtivado" else "Clique Automático\nDesligado"
	autoClickBotao.TextColor3 = if autoClickLigado then cores.verde else cores.vermelho
	autoOPBotao.Text = if player:GetAttribute("Passe_AutoClickOP") then "Autoclic OP\nAtivo" else "Autoclic OP\n💎"
	local vitoriasAuto = player:GetAttribute("VitoriasAutoLigado") == true
	vitoriasAutoBotao.Text = if vitoriasAuto then "Vitórias Automáticas\nLIGADO" else "Vitórias Automáticas\nDESLIGADO"
	vitoriasAutoBotao.BackgroundColor3 = if vitoriasAuto then cores.verde else cores.vermelho

	for nome, b in passeBotoes do
		local passe = Config.Gamepasses[nome]
		b.Text = if player:GetAttribute(`Passe_{nome}`) then `{passe.Nome}\n✅ Comprado` else `{passe.Nome}\n💎 Comprar`
	end

	local passo = Config.Tutorial[get("Tutorial")]
	tutorial.Visible = passo ~= nil
	if passo then
		tutorialTitulo.Text = ` Passo {get("Tutorial")} de {#Config.Tutorial} TUTORIAL`
		tutorialTexto.Text = passo.Texto
		tutorialProgresso.Text = `{formatar(get("TutorialProgresso"))} / {formatar(passo.Meta)} {passo.Unidade}`
	end
	toqueLabel.Visible = passo == nil or passo.Tipo == "Clique"

	aviso.Visible = Recompensas.prontos() > 0
end

UI.aoAtualizar(atualizarHUD)
player.AttributeChanged:Connect(UI.atualizarTudo)
UI.atualizarTudo()

-- Atualiza contadores de tempo (boosts, presentes) mesmo sem mudanças de atributo
task.spawn(function()
	while true do
		task.wait(1)
		boostsLabel.Text = Recompensas.boostsAtivos()
		aviso.Visible = Recompensas.prontos() > 0
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
