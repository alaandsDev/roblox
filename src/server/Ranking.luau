-- Placares globais (top 10) com OrderedDataStore, mostrados no hub do Mundo 1.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Ranking = {}

local INTERVALO = 120
local TOP = 10

local nomes: { [number]: string } = {}

local function nomeDe(userId: number): string
	if nomes[userId] then
		return nomes[userId]
	end
	local ok, nome = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	nomes[userId] = if ok then nome else "???"
	return nomes[userId]
end

local function formatar(n: number): string
	local sufixos = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local i = 1
	while n >= 1000 and i < #sufixos do
		n /= 1000
		i += 1
	end
	return if i == 1 then tostring(math.floor(n)) else string.format("%.1f%s", n, sufixos[i])
end

local function criarPlaca(titulo: string, posicao: Vector3): { TextLabel }
	local placa = Instance.new("Part")
	placa.Name = `Ranking_{titulo}`
	placa.Anchored = true
	placa.Size = Vector3.new(1, 16, 22)
	placa.Position = posicao
	placa.Color = Color3.fromRGB(70, 45, 25)
	placa.Material = Enum.Material.Wood
	placa.Parent = workspace:WaitForChild("Mundos")

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.Parent = placa

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = gui

	local function linha(texto: string, altura: number, cor: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, altura)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = cor
		label.Text = texto
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Parent = label
		label.Parent = gui
		return label
	end

	linha(titulo, 50, Color3.fromRGB(255, 210, 60))
	local linhas = {}
	for i = 1, TOP do
		linhas[i] = linha("", 30, Color3.new(1, 1, 1))
	end
	return linhas
end

function Ranking.iniciar(obterDados: (Player) -> any)
	local hub = Config.Pista.TamanhoHub
	local origem = Config.origemMundo(1)
	local placas = {
		{
			store = DataStoreService:GetOrderedDataStore("RankingRebirths_v1"),
			campo = "Rebirths",
			linhas = criarPlaca("Melhores Renascimentos", origem + Vector3.new(hub.X / 2 - 2, 8, -20)),
		},
		{
			store = DataStoreService:GetOrderedDataStore("RankingVitorias_v1"),
			campo = "VitoriasTotais",
			linhas = criarPlaca("Mais Vitórias", origem + Vector3.new(hub.X / 2 - 2, 8, -48)),
		},
	}

	task.spawn(function()
		while true do
			for _, placa in placas do
				for _, player in Players:GetPlayers() do
					local data = obterDados(player)
					if data then
						pcall(placa.store.SetAsync, placa.store, tostring(player.UserId), math.floor(data[placa.campo]))
					end
				end

				local ok, pagina = pcall(function()
					return placa.store:GetSortedAsync(false, TOP):GetCurrentPage()
				end)
				if ok then
					for i = 1, TOP do
						local entrada = pagina[i]
						placa.linhas[i].Text = if entrada
							then `{i}. {nomeDe(tonumber(entrada.key) or 0)} - {formatar(entrada.value)}`
							else ""
					end
				end
			end
			task.wait(INTERVALO)
		end
	end)
end

return Ranking
