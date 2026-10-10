-- Faz os pets equipados de todos os jogadores seguirem o dono, flutuando.
-- Usa o modelo de ReplicatedStorage.Modelos.Pets.<Tipo> se existir; senão, uma bolinha colorida.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Modelos = require(ReplicatedStorage.Shared.Modelos)

local TAMANHO = 2.2
local DISTANCIA = 5

local pasta = Instance.new("Folder")
pasta.Name = "PetsVisuais"
pasta.Parent = workspace

type Visual = { modelo: Model, cframe: CFrame? }
local porJogador: { [Player]: { visuais: { Visual }, json: string } } = {}

local function criarModelo(tipo: string, dourado: boolean): Model
	local modelo = Modelos.clonar("Pets", tipo)
	if modelo then
		Modelos.ajustarTamanho(modelo, TAMANHO)
	else
		modelo = Instance.new("Model")
		local corpo = Instance.new("Part")
		corpo.Shape = Enum.PartType.Ball
		corpo.Size = Vector3.one * TAMANHO
		corpo.Color = Config.Pets[tipo].Cor
		corpo.Material = Enum.Material.SmoothPlastic
		corpo.CanCollide = false
		corpo.CanTouch = false
		corpo.CanQuery = false
		corpo.Parent = modelo
		modelo.PrimaryPart = corpo
	end

	for _, obj in modelo:GetDescendants() do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			if dourado then
				obj.Color = Color3.fromRGB(255, 200, 40)
				obj.Material = Enum.Material.Foil
			end
		end
	end
	if dourado and modelo.PrimaryPart then
		local brilho = Instance.new("Sparkles")
		brilho.SparkleColor = Color3.fromRGB(255, 220, 80)
		brilho.Parent = modelo.PrimaryPart
	end
	modelo.Parent = pasta
	return modelo
end

local function limpar(player: Player)
	local info = porJogador[player]
	if info then
		for _, visual in info.visuais do
			visual.modelo:Destroy()
		end
	end
	porJogador[player] = nil
end

local function atualizarJogador(player: Player)
	local json = player:GetAttribute("PetsVisuais")
	if typeof(json) ~= "string" then
		return
	end
	local info = porJogador[player]
	if info and info.json == json then
		return
	end
	limpar(player)
	local ok, lista = pcall(HttpService.JSONDecode, HttpService, json)
	if not ok then
		return
	end
	local visuais = {}
	for _, pet in lista do
		if Config.Pets[pet.Tipo] then
			table.insert(visuais, { modelo = criarModelo(pet.Tipo, pet.Dourado), cframe = nil })
		end
	end
	porJogador[player] = { visuais = visuais, json = json }
end

local function observar(player: Player)
	player:GetAttributeChangedSignal("PetsVisuais"):Connect(function()
		atualizarJogador(player)
	end)
	atualizarJogador(player)
end

Players.PlayerAdded:Connect(observar)
Players.PlayerRemoving:Connect(limpar)
for _, player in Players:GetPlayers() do
	observar(player)
end

RunService.RenderStepped:Connect(function(dt)
	local tempo = os.clock()
	for player, info in porJogador do
		local character = player.Character
		local raiz = character and character:FindFirstChild("HumanoidRootPart")
		local quantidade = #info.visuais
		for i, visual in info.visuais do
			if not raiz or not raiz:IsA("BasePart") then
				visual.modelo.Parent = nil
				continue
			end
			visual.modelo.Parent = pasta
			-- Distribui os pets num arco atrás do jogador, mas fora do centro
			-- (no meio eles ficariam entre a câmera e o personagem)
			local graus = if quantidade == 1 then 50 else -70 + (i - 1) * 140 / (quantidade - 1)
			local angulo = math.rad(180 + graus)
			local deslocamento = Vector3.new(math.sin(angulo) * DISTANCIA, 0, -math.cos(angulo) * DISTANCIA)
			local flutuar = math.sin(tempo * 3 + i) * 0.4
			local alvo = raiz.CFrame * CFrame.new(deslocamento + Vector3.new(0, flutuar - 1, 0))
			alvo = CFrame.lookAt(alvo.Position, alvo.Position + raiz.CFrame.LookVector)
			local atual = if visual.cframe then visual.cframe:Lerp(alvo, math.min(1, dt * 10)) else alvo
			visual.cframe = atual
			visual.modelo:PivotTo(atual)
		end
	end
end)
