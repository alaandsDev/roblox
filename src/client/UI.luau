-- Funções de interface compartilhadas pelas janelas do cliente.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = {}

UI.player = player
UI.remotes = remotes

UI.cores = {
	amarelo = Color3.fromRGB(255, 205, 50),
	vermelho = Color3.fromRGB(220, 50, 50),
	marrom = Color3.fromRGB(60, 40, 20),
	verde = Color3.fromRGB(70, 190, 80),
	azul = Color3.fromRGB(60, 140, 255),
	roxo = Color3.fromRGB(150, 90, 220),
	cinza = Color3.fromRGB(120, 120, 120),
	fundo = Color3.fromRGB(40, 40, 50),
	linha = Color3.fromRGB(60, 60, 75),
}

local SUFIXOS = { "", "K", "M", "B", "T", "Qa", "Qi" }

function UI.formatar(n: number): string
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

function UI.formatarTempo(segundos: number): string
	segundos = math.max(0, math.floor(segundos))
	local h = segundos // 3600
	local m = (segundos % 3600) // 60
	local s = segundos % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%02d:%02d", m, s)
end

function UI.agora(): number
	return workspace:GetServerTimeNow()
end

function UI.get(key: string): any
	local value = player:GetAttribute(key)
	if value == nil then
		return Config.StartingData[key]
	end
	return value
end

-- Lê um atributo que o servidor guardou como JSON
function UI.json(key: string): any
	local value = player:GetAttribute(key)
	if typeof(value) == "string" then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, value)
		if ok then
			return decoded
		end
	end
	return Config.copiar(Config.StartingData[key] or {})
end

function UI.acao(nome: string, ...)
	remotes.Acao:FireServer(nome, ...)
end

function UI.create(className: string, props: { [string]: any }, children: { Instance }?): any
	local obj = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(obj :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = obj
		end
	end
	obj.Parent = props.Parent
	return obj
end

function UI.corner(raio: UDim?): UICorner
	return UI.create("UICorner", { CornerRadius = raio or UDim.new(0, 10) })
end

function UI.borda(espessura: number?): UIStroke
	return UI.create("UIStroke", {
		Thickness = espessura or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.texto(className: string, props: { [string]: any }): any
	props.Font = props.Font or Enum.Font.FredokaOne
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextScaled = true
	if props.BackgroundColor3 == nil then
		props.BackgroundTransparency = 1
	end
	return UI.create(className, props, { UI.create("UIStroke", { Thickness = 2 }) })
end

function UI.botao(props: { [string]: any }): TextButton
	local b = UI.texto("TextButton", props)
	UI.corner().Parent = b
	UI.borda().Parent = b
	UI.create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		Parent = b,
	})
	return b
end

UI.gui = UI.create("ScreenGui", { Name = "SimuladorGui", ResetOnSpawn = false, IgnoreGuiInset = false })

-- Janelas ---------------------------------------------------------------------------

local janelas: { Frame } = {}

function UI.abrir(janela: Frame)
	local abrir = not janela.Visible
	for _, outra in janelas do
		outra.Visible = false
	end
	janela.Visible = abrir
end

-- Cria uma janela central com título, botão X e uma lista rolável
function UI.janela(titulo: string): (Frame, ScrollingFrame)
	local frame = UI.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.65),
		BackgroundColor3 = UI.cores.fundo,
		Visible = false,
		ZIndex = 5,
		Parent = UI.gui,
	}, { UI.corner(), UI.borda(4), UI.create("UISizeConstraint", { MinSize = Vector2.new(340, 280) }) })
	table.insert(janelas, frame)

	UI.texto("TextLabel", {
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -70, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titulo,
		ZIndex = 5,
		Parent = frame,
	})

	local fechar = UI.botao({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = UI.cores.vermelho,
		Text = "X",
		ZIndex = 5,
		Parent = frame,
	})
	fechar.Activated:Connect(function()
		frame.Visible = false
	end)

	local lista = UI.create("ScrollingFrame", {
		Position = UDim2.new(0, 12, 0, 56),
		Size = UDim2.new(1, -24, 1, -68),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 6,
		ZIndex = 5,
		Parent = frame,
	}, { UI.create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

	return frame, lista
end

export type Linha = {
	frame: Frame,
	titulo: TextLabel,
	subtitulo: TextLabel,
	icone: Frame,
	botao: TextButton,
}

-- Linha padrão de lista: ícone colorido, título, subtítulo e um botão de ação
function UI.linha(lista: Instance, ordem: number, cor: Color3, titulo: string, subtitulo: string): Linha
	local frame = UI.create("Frame", {
		LayoutOrder = ordem,
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundColor3 = UI.cores.linha,
		ZIndex = 5,
		Parent = lista,
	}, { UI.corner() })

	local icone = UI.create("Frame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = cor,
		ZIndex = 5,
		Parent = frame,
	}, { UI.corner(UDim.new(1, 0)), UI.borda(3) })

	local tituloLabel = UI.texto("TextLabel", {
		Position = UDim2.new(0, 64, 0, 6),
		Size = UDim2.new(1, -200, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titulo,
		ZIndex = 5,
		Parent = frame,
	})
	local subtituloLabel = UI.texto("TextLabel", {
		Position = UDim2.new(0, 64, 0, 34),
		Size = UDim2.new(1, -200, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 120, 120),
		Text = subtitulo,
		ZIndex = 5,
		Parent = frame,
	})

	local botao = UI.botao({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(120, 46),
		ZIndex = 5,
		Parent = frame,
	})

	return { frame = frame, titulo = tituloLabel, subtitulo = subtituloLabel, icone = icone, botao = botao }
end

-- Atualização da tela: cada janela registra sua função de refresh aqui
local atualizacoes: { () -> () } = {}

function UI.aoAtualizar(fn: () -> ())
	table.insert(atualizacoes, fn)
end

function UI.atualizarTudo()
	for _, fn in atualizacoes do
		fn()
	end
end

-- Notificações ----------------------------------------------------------------------

local notificacao = UI.texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 190),
	Size = UDim2.new(0.5, 0, 0, 40),
	TextColor3 = UI.cores.amarelo,
	Visible = false,
	ZIndex = 10,
	Parent = UI.gui,
})

local idNotificacao = 0
function UI.notificar(mensagem: string)
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
remotes:WaitForChild("Notificar").OnClientEvent:Connect(UI.notificar)

return UI
