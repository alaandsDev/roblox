-- Gera cada mundo: área de spawn (hub) quadriculada, ovos e a pista com as paredes.
-- Tudo fica em Workspace.Mundos. Você pode decorar à vontade no Studio em volta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Modelos = require(ReplicatedStorage.Shared.Modelos)

local Mundo = {}

local function formatar(n: number): string
	local sufixos = { "", "K", "M", "B", "T", "Qa" }
	local i = 1
	while n >= 1000 and i < #sufixos do
		n /= 1000
		i += 1
	end
	return if i == 1 then tostring(math.floor(n)) else string.format("%g%s", math.floor(n * 10) / 10, sufixos[i])
end

local function texto(pai: Instance, conteudo: string, tamanho: UDim2, posicao: UDim2?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = tamanho
	label.Position = posicao or UDim2.new()
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = conteudo
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = pai
	return label
end

-- Piso quadriculado com studs (visual "LEGO")
local function quadriculado(pai: Instance, centro: Vector3, tamanho: Vector3, cor1: Color3, cor2: Color3)
	local lado = Config.Pista.TamanhoPiso
	local colunas = math.ceil(tamanho.X / lado)
	local linhas = math.ceil(tamanho.Z / lado)
	for x = 0, colunas - 1 do
		for z = 0, linhas - 1 do
			local piso = Instance.new("Part")
			piso.Anchored = true
			piso.Size = Vector3.new(lado, 1, lado)
			piso.Position = centro
				+ Vector3.new((x + 0.5) * lado - colunas * lado / 2, -0.45, (z + 0.5) * lado - linhas * lado / 2)
			piso.Color = if (x + z) % 2 == 0 then cor1 else cor2
			piso.Material = Enum.Material.Plastic
			piso.TopSurface = Enum.SurfaceType.Studs
			piso.Parent = pai
		end
	end
end

function Mundo.spawn(indice: number): CFrame
	local posicao = Config.origemMundo(indice) + Vector3.new(0, 4, -12)
	return CFrame.lookAt(posicao, posicao + Vector3.new(0, 0, 1))
end

local function criarOvo(pasta: Instance, ovo, posicao: Vector3, aoAbrir: (Player, string) -> ())
	local base = Instance.new("Part")
	base.Name = `Ovo_{ovo.Id}`
	base.Anchored = true
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(1, 9, 9)
	base.CFrame = CFrame.new(posicao + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	base.Color = Color3.fromRGB(255, 215, 60)
	base.Material = Enum.Material.Neon
	base.Parent = pasta

	local modelo = Modelos.clonar("Ovos", ovo.Id)
	if modelo then
		Modelos.ajustarTamanho(modelo, 6)
		modelo:PivotTo(CFrame.new(posicao + Vector3.new(0, 4.5, 0)))
		for _, obj in modelo:GetDescendants() do
			if obj:IsA("BasePart") then
				obj.Anchored = true
			end
		end
		modelo.Parent = base
	else
		local casca = Instance.new("Part")
		casca.Anchored = true
		casca.CanCollide = false
		casca.Shape = Enum.PartType.Ball
		casca.Size = Vector3.new(5, 5, 5)
		casca.Position = posicao + Vector3.new(0, 4, 0)
		casca.Color = ovo.Cor
		casca.Material = Enum.Material.SmoothPlastic
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(1, 1.3, 1)
		mesh.Parent = casca
		casca.Parent = base
	end

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 160)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 10, 0)
	gui.MaxDistance = 80
	gui.Adornee = base
	gui.Parent = base

	texto(gui, ovo.Nome, UDim2.new(1, 0, 0, 34))
	local custo = texto(gui, `🏆 {formatar(ovo.Custo)}`, UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 34))
	custo.TextColor3 = Color3.fromRGB(255, 220, 60)
	for i, entrada in ovo.Pets do
		local pet = Config.Pets[entrada.Pet]
		local linha = texto(gui, `{pet.Nome} {entrada.Chance}%`, UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 40 + i * 22))
		linha.TextColor3 = Config.Raridades[pet.Raridade]
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Abrir"
	prompt.ObjectText = `{ovo.Nome} (🏆 {formatar(ovo.Custo)})`
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
	prompt.Triggered:Connect(function(player)
		aoAbrir(player, ovo.Id)
	end)
end

local function criarParede(pasta: Instance, mundo: number, indice: number, origem: Vector3)
	local p = Config.Pista
	local info = Config.Paredes[indice]
	local vida = info.Vida * Config.Mundos[mundo].MultVida
	local vitorias = info.Vitorias * Config.Mundos[mundo].MultVitorias

	local parede = Instance.new("Part")
	parede.Name = `Parede{indice}`
	parede.Anchored = true
	parede.Size = Vector3.new(p.Largura, p.AlturaParede, 2)
	parede.Position = origem + Vector3.new(0, p.AlturaParede / 2, indice * p.Espacamento)
	parede.Color = Color3.fromHSV((indice - 1) / #Config.Paredes * 0.8, 0.75, 1)
	parede.Material = Enum.Material.Plastic
	parede.FrontSurface = Enum.SurfaceType.Studs
	parede.BackSurface = Enum.SurfaceType.Studs
	parede:SetAttribute("Mundo", mundo)
	parede:SetAttribute("Indice", indice)
	parede:SetAttribute("Vida", vida)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.Parent = parede
	texto(gui, `🛡️ {formatar(vida)}\n🏆 +{formatar(vitorias)}`, UDim2.fromScale(1, 0.5), UDim2.fromScale(0, 0.25))

	parede.Parent = pasta
	return parede
end

-- Cria todos os mundos. Retorna a lista de paredes.
function Mundo.construir(aoAbrirOvo: (Player, string) -> ()): { BasePart }
	local raiz = Instance.new("Folder")
	raiz.Name = "Mundos"
	local paredes = {}

	for indice, mundo in Config.Mundos do
		local origem = Config.origemMundo(indice)
		local pasta = Instance.new("Folder")
		pasta.Name = mundo.Nome

		-- Hub atrás do início da pista (z negativo)
		local hub = Config.Pista.TamanhoHub
		local chaoHub = Instance.new("Folder")
		chaoHub.Name = "Hub"
		chaoHub.Parent = pasta
		quadriculado(chaoHub, origem + Vector3.new(0, 0, -hub.Z / 2), hub, mundo.Cores[3], mundo.Cores[4])

		local placa = Instance.new("Part")
		placa.Name = "Placa"
		placa.Anchored = true
		placa.Size = Vector3.new(14, 3, 1)
		placa.Position = origem + Vector3.new(0, 20, 2)
		placa.Transparency = 1
		placa.CanCollide = false
		placa.Parent = pasta
		local guiPlaca = Instance.new("SurfaceGui")
		guiPlaca.Face = Enum.NormalId.Front
		guiPlaca.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		guiPlaca.PixelsPerStud = 20
		guiPlaca.Parent = placa
		texto(guiPlaca, mundo.Nome, UDim2.fromScale(1, 1))

		-- Ovos deste mundo, enfileirados no lado esquerdo do hub
		local ovos = Instance.new("Folder")
		ovos.Name = "Ovos"
		ovos.Parent = pasta
		local k = 0
		for _, ovo in Config.Ovos do
			if ovo.Mundo == indice then
				k += 1
				criarOvo(ovos, ovo, origem + Vector3.new(-hub.X / 2 + 10, 0, -10 - (k - 1) * 14), aoAbrirOvo)
			end
		end

		-- Pista
		local p = Config.Pista
		local comprimento = (#Config.Paredes + 1) * p.Espacamento
		local pista = Instance.new("Folder")
		pista.Name = "Pista"
		pista.Parent = pasta
		quadriculado(
			pista,
			origem + Vector3.new(0, 0, comprimento / 2),
			Vector3.new(p.Largura, 1, comprimento),
			mundo.Cores[1],
			mundo.Cores[2]
		)
		for i = 1, #Config.Paredes do
			table.insert(paredes, criarParede(pista, indice, i, origem))
		end

		pasta.Parent = raiz
	end

	raiz.Parent = workspace
	return paredes
end

return Mundo
