local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local AMARELO = Color3.fromRGB(255, 205, 50)
local VERMELHO = Color3.fromRGB(220, 50, 50)
local MARROM = Color3.fromRGB(60, 40, 20)
local VERDE = Color3.fromRGB(70, 190, 80)
local AZUL = Color3.fromRGB(60, 140, 255)

local SUFIXOS = { "", "K", "M", "B", "T", "Qa", "Qi" }

local function formatar(n: number): string
	local i = 1
	while n >= 1000 and i < #SUFIXOS do
		n /= 1000
		i += 1
	end
	if i == 1 then
		return tostring(math.floor(n))
	end
	return string.format("%.1f%s", n, SUFIXOS[i])
end

local function get(key: string)
	local value = player:GetAttribute(key)
	if value == nil then
		return Config.StartingData[key]
	end
	return value
end

local function escudosComprados(): { [string]: boolean }
	local json = player:GetAttribute("Escudos")
	if typeof(json) ~= "string" then
		return { Madeira = true }
	end
	return HttpService:JSONDecode(json)
end

-- Helpers de criação de interface ---------------------------------------------

local function create(className: string, props: { [string]: any }, children: { Instance }?)
	local obj = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			obj[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = obj
	end
	obj.Parent = props.Parent
	return obj
end

local function corner(raio: UDim?)
	return create("UICorner", { CornerRadius = raio or UDim.new(0, 10) })
end

local function borda(espessura: number?)
	return create("UIStroke", {
		Thickness = espessura or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function texto(className: string, props: { [string]: any })
	props.Font = props.Font or Enum.Font.FredokaOne
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextScaled = true
	if props.BackgroundColor3 == nil then
		props.BackgroundTransparency = 1
	end
	return create(className, props, { create("UIStroke", { Thickness = 2 }) })
end

local function botao(props: { [string]: any }): TextButton
	local b = texto("TextButton", props)
	corner().Parent = b
	borda().Parent = b
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		Parent = b,
	})
	return b
end

local gui = create("ScreenGui", { Name = "SimuladorGui", ResetOnSpawn = false })

-- Notificações ----------------------------------------------------------------

local notificacao = texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 200),
	Size = UDim2.new(0.5, 0, 0, 40),
	TextColor3 = AMARELO,
	Visible = false,
	Parent = gui,
})

local idNotificacao = 0
local function notificar(mensagem: string)
	idNotificacao += 1
	local meu = idNotificacao
	notificacao.Text = mensagem
	notificacao.Visible = true
	task.delay(3, function()
		if idNotificacao == meu then
			notificacao.Visible = false
		end
	end)
end
remotes.Notificar.OnClientEvent:Connect(notificar)

-- Topo esquerdo: vitórias e rebirths -------------------------------------------

local stats = create("Frame", {
	Position = UDim2.new(0, 16, 0, 16),
	Size = UDim2.fromOffset(160, 90),
	BackgroundTransparency = 1,
	Parent = gui,
}, { create("UIListLayout", { Padding = UDim.new(0, 4) }) })

local vitoriasLabel = texto("TextLabel", {
	Size = UDim2.new(1, 0, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = stats,
})
local rebirthsLabel = texto("TextLabel", {
	Size = UDim2.new(1, 0, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = stats,
})

-- Tutorial --------------------------------------------------------------------

local tutorial = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0.45, 0, 0, 120),
	BackgroundColor3 = Color3.fromRGB(30, 30, 30),
	Parent = gui,
}, { corner(), borda(4) })

local tutorialTitulo = texto("TextLabel", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = Color3.fromRGB(170, 120, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = tutorial,
})
corner().Parent = tutorialTitulo

local tutorialTexto = texto("TextLabel", {
	Position = UDim2.new(0, 8, 0, 40),
	Size = UDim2.new(1, -16, 0, 44),
	Parent = tutorial,
})

local tutorialProgresso = texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, 6),
	Size = UDim2.new(0.8, 0, 0, 44),
	Parent = tutorial,
})

-- Botão TOQUE! ----------------------------------------------------------------

local toqueLabel = texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.72, 0, 0.45, -75),
	Size = UDim2.fromOffset(200, 50),
	TextColor3 = AMARELO,
	Text = "TOQUE!",
	Parent = gui,
})

local TAMANHO_TOQUE = UDim2.fromOffset(130, 130)
local toque = create("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.72, 0, 0.45, 0),
	Size = TAMANHO_TOQUE,
	BackgroundColor3 = Color3.new(1, 1, 1),
	Text = "👆",
	TextScaled = true,
	Parent = gui,
}, {
	corner(UDim.new(1, 0)),
	create("UIStroke", { Thickness = 8, Color = AMARELO, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})

local function mostrarGanho()
	local ganho = texto("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = toque.Position + UDim2.fromOffset(math.random(-60, 60), -40),
		Size = UDim2.fromOffset(120, 36),
		TextColor3 = AMARELO,
		Text = `+{formatar(get("GanhoPorClique") or 1)} 🛡️`,
		Parent = gui,
	})
	TweenService:Create(ganho, TweenInfo.new(0.8), {
		Position = ganho.Position - UDim2.fromOffset(0, 80),
		TextTransparency = 1,
	}):Play()
	task.delay(0.8, ganho.Destroy, ganho)
end

local function clicar()
	remotes.Click:FireServer()
	mostrarGanho()
end

toque.Activated:Connect(function()
	clicar()
	toque.Size = TAMANHO_TOQUE - UDim2.fromOffset(16, 16)
	TweenService:Create(toque, TweenInfo.new(0.12), { Size = TAMANHO_TOQUE }):Play()
end)

-- Barra de baixo: armadura, nível, autoclick ----------------------------------

local armaduraLabel = texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -82),
	Size = UDim2.fromOffset(300, 40),
	Parent = gui,
})

local barra = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(340, 62),
	BackgroundColor3 = MARROM,
	ClipsDescendants = true,
	Parent = gui,
}, { corner(), borda(4) })

local barraXP = create("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(110, 80, 30),
	BorderSizePixel = 0,
	Parent = barra,
}, { corner() })

local nivelLabel = texto("TextLabel", {
	Position = UDim2.new(0, 12, 0, 6),
	Size = UDim2.new(0.5, -12, 1, -12),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = barra,
})
local xpLabel = texto("TextLabel", {
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0.5, -12, 1, -28),
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = barra,
})

local infoEsquerda = create("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(0.5, -180, 1, -16),
	Size = UDim2.fromOffset(170, 56),
	BackgroundTransparency = 1,
	Parent = gui,
}, { create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

local velocidadeLabel = texto("TextLabel", {
	Size = UDim2.new(1, 0, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = infoEsquerda,
})
local multLabel = texto("TextLabel", {
	Size = UDim2.new(1, 0, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = infoEsquerda,
})

local autoBotoes = create("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0.5, 180, 1, -16),
	Size = UDim2.fromOffset(170, 120),
	BackgroundTransparency = 1,
	Parent = gui,
}, { create("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom }) })

local autoOPBotao = botao({
	Size = UDim2.new(1, 0, 0, 52),
	BackgroundColor3 = AMARELO,
	TextColor3 = VERMELHO,
	Parent = autoBotoes,
})
local autoBotao = botao({
	Size = UDim2.new(1, 0, 0, 52),
	BackgroundColor3 = Color3.new(1, 1, 1),
	TextColor3 = VERMELHO,
	Parent = autoBotoes,
})

local autoClickLigado = false

local function intervaloAutoClick(): number
	if player:GetAttribute("Passe_AutoClickOP") then
		return Config.AutoClickOPIntervalo
	end
	return Config.AutoClickIntervalo
end

task.spawn(function()
	while true do
		task.wait(intervaloAutoClick())
		if autoClickLigado then
			clicar()
		end
	end
end)

-- Gamepasses ------------------------------------------------------------------

local function comprarPasse(nome: string)
	local passe = Config.Gamepasses[nome]
	if player:GetAttribute(`Passe_{nome}`) then
		return
	end
	if passe.Id == 0 then
		notificar(`Configure o ID do gamepass "{passe.Nome}" no Config.luau`)
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, passe.Id)
end

autoBotao.Activated:Connect(function()
	autoClickLigado = not autoClickLigado
end)
autoOPBotao.Activated:Connect(function()
	comprarPasse("AutoClickOP")
end)

local passesColuna = create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromOffset(190, 260),
	BackgroundTransparency = 1,
	Parent = gui,
}, { create("UIListLayout", { Padding = UDim.new(0, 10) }) })

local passeBotoes = {}
for _, info in {
	{ "DobroArmadura", VERMELHO },
	{ "DobroVitorias", AMARELO },
	{ "Velocidade", AZUL },
} do
	local nome, cor = info[1], info[2]
	local b = botao({ Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = cor, Parent = passesColuna })
	b.Activated:Connect(function()
		comprarPasse(nome)
	end)
	passeBotoes[nome] = b
end

-- Menu esquerdo e janelas -----------------------------------------------------

local menu = create("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(130, 130),
	BackgroundTransparency = 1,
	Parent = gui,
}, { create("UIListLayout", { Padding = UDim.new(0, 10) }) })

local function janela(titulo: string): (Frame, ScrollingFrame)
	local frame = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.5, 0, 0.6, 0),
		BackgroundColor3 = Color3.fromRGB(40, 40, 50),
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	}, { corner(), borda(4), create("UISizeConstraint", { MinSize = Vector2.new(320, 260) }) })

	texto("TextLabel", {
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -70, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titulo,
		ZIndex = 5,
		Parent = frame,
	})

	local fechar = botao({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = VERMELHO,
		Text = "X",
		ZIndex = 5,
		Parent = frame,
	})
	fechar.Activated:Connect(function()
		frame.Visible = false
	end)

	local lista = create("ScrollingFrame", {
		Position = UDim2.new(0, 12, 0, 56),
		Size = UDim2.new(1, -24, 1, -68),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 6,
		ZIndex = 5,
		Parent = frame,
	}, { create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

	return frame, lista
end

local lojaJanela, lojaLista = janela("🛡️ Escudos")
local rebirthJanela, rebirthLista = janela("🔁 Rebirth")

local lojaBotao = botao({ Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = AZUL, Text = "🛡️ Escudos", Parent = menu })
local rebirthMenuBotao = botao({ Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = VERDE, Text = "🔁 Rebirth", Parent = menu })

lojaBotao.Activated:Connect(function()
	lojaJanela.Visible = not lojaJanela.Visible
	rebirthJanela.Visible = false
end)
rebirthMenuBotao.Activated:Connect(function()
	rebirthJanela.Visible = not rebirthJanela.Visible
	lojaJanela.Visible = false
end)

local linhasEscudo = {}
for ordem, escudo in Config.Escudos do
	local linha = create("Frame", {
		LayoutOrder = ordem,
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundColor3 = Color3.fromRGB(60, 60, 75),
		ZIndex = 5,
		Parent = lojaLista,
	}, { corner() })

	create("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = escudo.Cor,
		ZIndex = 5,
		Parent = linha,
	}, { corner(UDim.new(1, 0)), borda(3) })

	texto("TextLabel", {
		Position = UDim2.new(0, 64, 0, 6),
		Size = UDim2.new(1, -200, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = escudo.Nome,
		ZIndex = 5,
		Parent = linha,
	})
	texto("TextLabel", {
		Position = UDim2.new(0, 64, 0, 34),
		Size = UDim2.new(1, -200, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 90, 90),
		Text = `+{escudo.Bonus} Armadura por toque`,
		ZIndex = 5,
		Parent = linha,
	})

	local acao = botao({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(120, 46),
		ZIndex = 5,
		Parent = linha,
	})
	acao.Activated:Connect(function()
		if escudosComprados()[escudo.Id] then
			remotes.EquiparEscudo:FireServer(escudo.Id)
		else
			remotes.ComprarEscudo:FireServer(escudo.Id)
		end
	end)
	linhasEscudo[escudo.Id] = acao
end

local rebirthInfo = texto("TextLabel", {
	Size = UDim2.new(1, -8, 0, 100),
	TextWrapped = true,
	ZIndex = 5,
	Parent = rebirthLista,
})
local rebirthBotao = botao({
	Size = UDim2.new(1, -8, 0, 56),
	BackgroundColor3 = VERDE,
	Text = "Renascer",
	ZIndex = 5,
	Parent = rebirthLista,
})
rebirthBotao.Activated:Connect(function()
	remotes.Rebirth:FireServer()
end)

-- Atualização da tela ----------------------------------------------------------

local nivelAnterior = get("Nivel")

local function refresh()
	local nivel = get("Nivel")
	local rebirths = get("Rebirths")
	local vitorias = get("Vitorias")
	local dobro = player:GetAttribute("Passe_DobroArmadura") == true

	if nivel > nivelAnterior then
		notificar(`⬆️ Nível {nivel}!`)
	end
	nivelAnterior = nivel

	vitoriasLabel.Text = `🏆 {formatar(vitorias)}`
	rebirthsLabel.Text = `🔁 {rebirths}`
	armaduraLabel.Text = `Armor: {formatar(get("Armadura"))}`

	local necessario = Config.xpParaNivel(nivel)
	nivelLabel.Text = `Nível {nivel}`
	xpLabel.Text = `{get("XP")} / {necessario}`
	barraXP.Size = UDim2.fromScale(get("XP") / necessario, 1)

	local velocidade = Config.VelocidadeBase
		+ (if player:GetAttribute("Passe_Velocidade") then Config.VelocidadeGamepass else 0)
	velocidadeLabel.Text = `👟 Velocidade: {velocidade}`
	multLabel.Text = `🛡️ x{string.format("%.2f", Config.multiplicador(nivel, rebirths, dobro))} Armadura`

	autoBotao.Text = if autoClickLigado then "Clique Automático: Ligado" else "Clique Automático: Desligado"
	autoBotao.TextColor3 = if autoClickLigado then VERDE else VERMELHO
	autoOPBotao.Text = if player:GetAttribute("Passe_AutoClickOP") then "Autoclic OP: Ativo" else "Autoclic OP 💎"

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
	local mostrarToque = passo ~= nil and passo.Tipo == "Clique"
	toqueLabel.Visible = mostrarToque or not passo

	local comprados = escudosComprados()
	local equipado = get("EscudoEquipado")
	for _, escudo in Config.Escudos do
		local acao = linhasEscudo[escudo.Id]
		if equipado == escudo.Id then
			acao.Text = "Equipado"
			acao.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
		elseif comprados[escudo.Id] then
			acao.Text = "Equipar"
			acao.BackgroundColor3 = AZUL
		else
			acao.Text = `🏆 {formatar(escudo.Custo)}`
			acao.BackgroundColor3 = if vitorias >= escudo.Custo then VERDE else VERMELHO
		end
	end

	local nivelRebirth = Config.nivelParaRebirth(rebirths)
	rebirthInfo.Text = `Precisa de nível {nivelRebirth}. Zera armadura, vitórias e nível, `
		.. `mas você mantém os escudos e ganha +{Config.BonusPorRebirth * 100}% de armadura para sempre.`
	rebirthBotao.BackgroundColor3 = if nivel >= nivelRebirth then VERDE else VERMELHO
end

player.AttributeChanged:Connect(refresh)
autoBotao.Activated:Connect(refresh)
refresh()

gui.Parent = player:WaitForChild("PlayerGui")
