-- Gera a pista com as paredes no Workspace. Se você montar a pista à mão no Studio,
-- crie uma pasta Workspace.Pista.Paredes com Parts que tenham os atributos Indice e Vida.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Pista = {}

local function formatar(n: number): string
	local sufixos = { "", "K", "M", "B", "T" }
	local i = 1
	while n >= 1000 and i < #sufixos do
		n /= 1000
		i += 1
	end
	return if i == 1 then tostring(n) else string.format("%g%s", math.floor(n * 10) / 10, sufixos[i])
end

local function criarPlaca(parede: BasePart, texto: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.Parent = parede

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.5)
	label.Position = UDim2.fromScale(0, 0.25)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = texto
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
end

-- Retorna a pasta com as paredes, criando a pista se ela ainda não existir
function Pista.obterParedes(): Folder
	local existente = workspace:FindFirstChild("Pista")
	if existente and existente:FindFirstChild("Paredes") then
		return existente.Paredes
	end

	local p = Config.Pista
	local pasta = Instance.new("Folder")
	pasta.Name = "Pista"

	-- Chão quadriculado com studs (o visual "LEGO")
	local comprimento = (#Config.Paredes + 1) * p.Espacamento
	local chao = Instance.new("Model")
	chao.Name = "Chao"
	local colunas = math.ceil(p.Largura / p.TamanhoPiso)
	local linhas = math.ceil(comprimento / p.TamanhoPiso)
	for x = 0, colunas - 1 do
		for z = 0, linhas - 1 do
			local piso = Instance.new("Part")
			piso.Anchored = true
			piso.Size = Vector3.new(p.TamanhoPiso, 1, p.TamanhoPiso)
			piso.Position = p.Origem
				+ Vector3.new(
					(x + 0.5) * p.TamanhoPiso - colunas * p.TamanhoPiso / 2,
					-0.45,
					(z + 0.5) * p.TamanhoPiso
				)
			piso.Color = p.CoresPiso[(x + z) % 2 + 1]
			piso.Material = Enum.Material.Plastic
			piso.TopSurface = Enum.SurfaceType.Studs
			piso.Parent = chao
		end
	end
	chao.Parent = pasta

	local paredes = Instance.new("Folder")
	paredes.Name = "Paredes"
	paredes.Parent = pasta

	for indice, info in Config.Paredes do
		local parede = Instance.new("Part")
		parede.Name = `Parede{indice}`
		parede.Anchored = true
		parede.Size = Vector3.new(p.Largura, p.AlturaParede, 2)
		parede.Position = p.Origem + Vector3.new(0, p.AlturaParede / 2, indice * p.Espacamento)
		parede.Color = Color3.fromHSV((indice - 1) / #Config.Paredes * 0.8, 0.75, 1)
		parede.Material = Enum.Material.Plastic
		parede.FrontSurface = Enum.SurfaceType.Studs
		parede.BackSurface = Enum.SurfaceType.Studs
		parede:SetAttribute("Indice", indice)
		parede:SetAttribute("Vida", info.Vida)
		criarPlaca(parede, `🛡️ {formatar(info.Vida)}\n🏆 +{formatar(info.Vitorias)}`)
		parede.Parent = paredes
	end

	pasta.Parent = workspace
	return paredes
end

return Pista
