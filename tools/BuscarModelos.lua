--[[
	Busca modelos grátis na Creator Store e coloca em ReplicatedStorage.Modelos.

	COMO USAR:
	1. No Roblox Studio, abra o jogo e vá em View > Command Bar.
	2. Copie TODO este arquivo, cole na Command Bar e aperte Enter.
	3. Acompanhe na janela Output. No fim, confira os modelos na pasta
	   ReplicatedStorage > Modelos e apague/troque os que não gostar.

	- Pega o primeiro resultado cujo nome tem a palavra da categoria (pet/egg/shield) e que não
	  pareça kit, gear ou giver. Troque as palavras em BUSCAS se vier algo estranho.
	- Rode só UMA vez por vez (aperte Enter uma vez). Duplicatas são removidas no início.
	- Itens que já existem na pasta são pulados (rode de novo sem perder o que você escolheu).
	- Todos os scripts dentro dos modelos são apagados (proteção contra backdoor).
]]

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BUSCAS = {
	Pets = {
		Cachorro = "dog pet",
		Gato = "cat pet",
		Coelho = "bunny pet",
		Raposa = "fox pet",
		Panda = "panda pet",
		Unicornio = "unicorn pet",
		Pinguim = "penguin pet",
		Urso = "polar bear pet",
		Yeti = "yeti pet",
		Fenix = "phoenix pet",
		Salamandra = "lizard pet",
		Golem = "golem pet",
		Dragao = "dragon pet",
		Ursinho = "teddy bear pet",
		Cupcake = "cupcake pet",
		Arcoiris = "rainbow pet",
	},
	Ovos = {
		Basico = "simulator egg",
		Floresta = "forest egg",
		Neve = "ice egg",
		Lava = "lava egg",
		Doce = "candy egg pet",
	},
	Escudos = {
		Madeira = "wooden shield",
		Pedra = "stone shield",
		Ferro = "iron shield",
		Cavaleiro = "knight shield",
		Dragao = "dragon shield",
		Ouro = "golden shield",
		Diamante = "crystal shield",
		Fogo = "fire shield",
		Cosmico = "purple shield",
		Gelo = "ice shield",
		Magma = "lava shield",
		Galaxia = "star shield",
	},
}

local function pasta(pai, nome)
	local existente = pai:FindFirstChild(nome)
	if existente then
		return existente
	end
	local nova = Instance.new("Folder")
	nova.Name = nome
	nova.Parent = pai
	return nova
end

local function limpar(obj)
	for _, d in obj:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
end

-- Palavra que o nome do resultado precisa ter, por categoria
local PALAVRA = { Pets = "pet", Ovos = "egg", Escudos = "shield" }
-- Resultados com estas palavras no nome são pulados
local PROIBIDAS = { "kit", "gear", "giver", "tool", "build", "station", "killer", "hat", "anti" }

local function resultadoBom(categoria, nome)
	nome = string.lower(nome)
	if not string.find(nome, PALAVRA[categoria], 1, true) then
		return false
	end
	for _, palavra in PROIBIDAS do
		if string.find(nome, palavra, 1, true) then
			return false
		end
	end
	return true
end

local raiz = pasta(ReplicatedStorage, "Modelos")

-- Remove modelos duplicados (mesmo nome na mesma pasta)
for _, sub in raiz:GetChildren() do
	local vistos = {}
	for _, filho in sub:GetChildren() do
		if vistos[filho.Name] then
			filho:Destroy()
		else
			vistos[filho.Name] = true
		end
	end
end
local ok, falhas = 0, 0

for categoria, itens in BUSCAS do
	local destino = pasta(raiz, categoria)
	for id, busca in itens do
		if destino:FindFirstChild(id) then
			continue
		end
		local sucesso, erro = pcall(function()
			local paginas = InsertService:GetFreeModels(busca, 0)
			local resultado
			for _, r in (paginas[1] and paginas[1].Results) or {} do
				if resultadoBom(categoria, r.Name) then
					resultado = r
					break
				end
			end
			if not resultado then
				error("nenhum resultado bom; troque a palavra de busca")
			end
			local objetos = game:GetObjects("rbxassetid://" .. resultado.AssetId)
			local modelo = Instance.new("Model")
			modelo.Name = id
			for _, obj in objetos do
				obj.Parent = modelo
			end
			limpar(modelo)
			modelo.Parent = destino
			print(`[OK] {categoria}/{id} <- "{resultado.Name}" (asset {resultado.AssetId})`)
		end)
		if sucesso then
			ok += 1
		else
			falhas += 1
			warn(`[FALHOU] {categoria}/{id} ("{busca}"): {erro}`)
		end
	end
end

print(`Pronto! {ok} modelos adicionados, {falhas} falhas. Confira em ReplicatedStorage > Modelos.`)
