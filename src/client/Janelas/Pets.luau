-- Inventário de pets (equipar, apagar), fusão em dourado e a animação de abrir ovo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.Parent.UI)

local cores = UI.cores

local Pets = {}

local function nomePet(tipo: string, dourado: boolean): string
	local pet = Config.Pets[tipo]
	return if dourado then `{pet.Nome} Dourado` else pet.Nome
end

-- Inventário --------------------------------------------------------------------------

local petsJanela, petsLista = UI.janela("🐾 Pets")
Pets.Inventario = petsJanela

local topo = UI.create("Frame", {
	LayoutOrder = 0,
	Size = UDim2.new(1, -8, 0, 46),
	BackgroundTransparency = 1,
	ZIndex = 5,
	Parent = petsLista,
})
local resumo = UI.texto("TextLabel", {
	Size = UDim2.new(0.5, 0, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
	Parent = topo,
})
local melhoresBotao = UI.botao({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.new(0.45, 0, 1, 0),
	BackgroundColor3 = cores.verde,
	Text = "Equipar melhores",
	ZIndex = 5,
	Parent = topo,
})
melhoresBotao.Activated:Connect(function()
	UI.acao("EquiparMelhores")
end)

local linhasPet: { Instance } = {}
local ultimoJson = ""

local function reconstruirInventario()
	local pets = UI.json("Pets")
	local equipados = UI.json("PetsEquipados")
	for _, linha in linhasPet do
		linha:Destroy()
	end
	linhasPet = {}

	table.sort(pets, function(a, b)
		return Config.bonusPet(a.Tipo, a.Dourado) > Config.bonusPet(b.Tipo, b.Dourado)
	end)

	for ordem, pet in pets do
		local info = Config.Pets[pet.Tipo]
		if not info then
			continue
		end
		local equipado = table.find(equipados, pet.Id) ~= nil
		local linha = UI.linha(
			petsLista,
			ordem,
			info.Cor,
			nomePet(pet.Tipo, pet.Dourado),
			`+{math.floor(Config.bonusPet(pet.Tipo, pet.Dourado) * 100)}% Armadura · {info.Raridade}`
		)
		linha.titulo.TextColor3 = if pet.Dourado then cores.amarelo else Config.Raridades[info.Raridade]
		linha.subtitulo.TextColor3 = Color3.fromRGB(220, 220, 220)
		linha.titulo.Size = UDim2.new(1, -250, 0, 28)
		linha.subtitulo.Size = UDim2.new(1, -250, 0, 24)
		linha.botao.Text = if equipado then "Tirar" else "Equipar"
		linha.botao.BackgroundColor3 = if equipado then cores.cinza else cores.azul
		linha.botao.Activated:Connect(function()
			UI.acao(if equipado then "DesequiparPet" else "EquiparPet", pet.Id)
		end)

		local apagar = UI.botao({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -134, 0.5, 0),
			Size = UDim2.fromOffset(46, 46),
			BackgroundColor3 = cores.vermelho,
			Text = "🗑",
			ZIndex = 5,
			Parent = linha.frame,
		})
		local confirmar = false
		apagar.Activated:Connect(function()
			if confirmar then
				UI.acao("ApagarPet", pet.Id)
			else
				confirmar = true
				apagar.Text = "?"
				task.delay(2, function()
					confirmar = false
					apagar.Text = "🗑"
				end)
			end
		end)
		table.insert(linhasPet, linha.frame)
	end
end

UI.aoAtualizar(function()
	local pets = UI.json("Pets")
	resumo.Text = `{#UI.json("PetsEquipados")}/{UI.get("MaxEquipados") or Config.PetsEquipadosBase} equipados · {#pets}/{Config.MaxPets}`
	local json = `{UI.player:GetAttribute("Pets")}|{UI.player:GetAttribute("PetsEquipados")}`
	if json ~= ultimoJson then
		ultimoJson = json
		reconstruirInventario()
	end
end)

-- Fusão -------------------------------------------------------------------------------

local fusaoJanela, fusaoLista = UI.janela(`🔮 Fusão ({Config.FusaoQuantidade} iguais = 1 Dourado)`)
Pets.Fusao = fusaoJanela

local linhasFusao: { [string]: UI.Linha } = {}
local tiposOrdenados = {}
for tipo in Config.Pets do
	table.insert(tiposOrdenados, tipo)
end
table.sort(tiposOrdenados, function(a, b)
	return Config.Pets[a].Bonus < Config.Pets[b].Bonus
end)

for ordem, tipo in tiposOrdenados do
	local info = Config.Pets[tipo]
	local linha = UI.linha(fusaoLista, ordem, info.Cor, `{info.Nome} → Dourado`, "")
	linha.subtitulo.TextColor3 = cores.amarelo
	linha.botao.Text = "Fundir"
	linha.botao.Activated:Connect(function()
		UI.acao("FundirPet", tipo)
	end)
	linhasFusao[tipo] = linha
end

UI.aoAtualizar(function()
	local contagem = {}
	for _, pet in UI.json("Pets") do
		if not pet.Dourado then
			contagem[pet.Tipo] = (contagem[pet.Tipo] or 0) + 1
		end
	end
	for tipo, linha in linhasFusao do
		local qtd = contagem[tipo] or 0
		linha.frame.Visible = qtd > 0
		linha.subtitulo.Text = `Você tem {qtd}/{Config.FusaoQuantidade} · dourado dá x{Config.MultDourado} bônus`
		linha.botao.BackgroundColor3 = if qtd >= Config.FusaoQuantidade then cores.verde else cores.vermelho
	end
end)

-- Animação de ovo aberto -----------------------------------------------------------------

local popup = UI.create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(300, 300),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 20,
	Parent = UI.gui,
})
local popupOvo = UI.create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.fromOffset(150, 190),
	ZIndex = 20,
	Parent = popup,
}, { UI.corner(UDim.new(1, 0)), UI.borda(5) })
local popupTitulo = UI.texto("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.78),
	Size = UDim2.new(1, 0, 0, 44),
	ZIndex = 20,
	Parent = popup,
})

local fila: { { string } } = {}
local animando = false

local function animarProximo()
	if animando or #fila == 0 then
		return
	end
	animando = true
	local ovoId, tipo = fila[1][1], fila[1][2]
	table.remove(fila, 1)

	local ovo = Config.getOvo(ovoId)
	local pet = Config.Pets[tipo]
	popup.Visible = true
	popupOvo.BackgroundColor3 = if ovo then ovo.Cor else Color3.new(1, 1, 1)
	popupOvo.Rotation = 0
	popupTitulo.Text = "..."
	popupTitulo.TextColor3 = Color3.new(1, 1, 1)

	-- Balança o ovo e revela o pet
	for i = 1, 6 do
		TweenService:Create(popupOvo, TweenInfo.new(0.12), { Rotation = if i % 2 == 0 then 15 else -15 }):Play()
		task.wait(0.12)
	end
	popupOvo.Rotation = 0
	popupOvo.BackgroundColor3 = pet.Cor
	popupTitulo.Text = `{pet.Nome}!`
	popupTitulo.TextColor3 = Config.Raridades[pet.Raridade]
	popupOvo.Size = UDim2.fromOffset(100, 100)
	TweenService:Create(popupOvo, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(170, 170) })
		:Play()
	task.wait(1.6)

	popup.Visible = false
	popupOvo.Size = UDim2.fromOffset(150, 190)
	animando = false
	animarProximo()
end

UI.remotes:WaitForChild("OvoAberto").OnClientEvent:Connect(function(ovoId: string, tipo: string)
	table.insert(fila, { ovoId, tipo })
	task.spawn(animarProximo)
end)

return Pets
