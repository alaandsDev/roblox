--[[
	Busca modelos grátis na Creator Store e coloca em ReplicatedStorage.Modelos.

	COMO USAR:
	1. No Roblox Studio, abra o jogo e vá em View > Command Bar.
	2. Copie TODO este arquivo, cole na Command Bar e aperte Enter.
	3. Acompanhe na janela Output. No fim, confira os modelos na pasta
	   ReplicatedStorage > Modelos e apague/troque os que não gostar.

	- Pega o primeiro resultado de cada busca. Troque as palavras em BUSCAS se vier algo estranho.
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
		Salamandra = "salamander pet",
		Golem = "lava golem pet",
		Dragao = "dragon pet",
		Ursinho = "gummy bear pet",
		Cupcake = "cupcake pet",
		Arcoiris = "rainbow cat pet",
	},
	Ovos = {
		Basico = "pet egg",
		Floresta = "forest egg",
		Neve = "snow egg",
		Lava = "lava egg",
		Doce = "candy egg",
	},
	Escudos = {
		Madeira = "wooden shield",
		Pedra = "stone shield",
		Ferro = "iron shield",
		Cavaleiro = "knight shield",
		Dragao = "dragon shield",
		Ouro = "golden shield",
		Diamante = "diamond shield",
		Fogo = "fire shield",
		Cosmico = "galaxy shield",
		Gelo = "ice shield",
		Magma = "magma shield",
		Galaxia = "space shield",
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

local raiz = pasta(ReplicatedStorage, "Modelos")
local ok, falhas = 0, 0

for categoria, itens in BUSCAS do
	local destino = pasta(raiz, categoria)
	for id, busca in itens do
		if destino:FindFirstChild(id) then
			continue
		end
		local sucesso, erro = pcall(function()
			local paginas = InsertService:GetFreeModels(busca, 0)
			local resultado = paginas[1] and paginas[1].Results and paginas[1].Results[1]
			if not resultado then
				error("nenhum resultado")
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
