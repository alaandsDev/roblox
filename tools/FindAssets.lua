--[[
	Busca assets grátis na Creator Store e coloca em ReplicatedStorage.Assets.<Categoria>.<Nome>.

	COMO USAR
	1. Abra build\RollLegends.rbxlx no Studio.
	2. Janela > Barra de comandos. Cole TODO este arquivo e aperte Enter UMA vez.
	3. Acompanhe na janela Saída. Itens que já existem são pulados.
	4. Revise o que veio. Depois: botão direito em ReplicatedStorage > Assets >
	   Salvar em arquivo > assets\Assets.rbxm, e faça commit.

	SEGURANÇA
	- Todos os scripts são removidos do que for baixado (backdoors são comuns).
	- Só aceita resultados cujo NOME contém uma das palavras exigidas.
	- Mesmo assim, revise cada asset antes de usar (veja SECURITY.md).

	Edite a tabela BUSCAS para pedir outros itens. Tipos: "Sound", "Decal" (ícone/imagem),
	"ParticleEmitter" (efeito), "Model" (qualquer modelo com partes), "Sky".
]]

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [Categoria] = { [Nome] = { tipo, { buscas... }, { palavras que o nome precisa ter } } }
local BUSCAS = {
	Sounds = {
		DiceRoll = { "Sound", { "dice roll sound", "dice shake sound" }, { "dice" } },
		CardFlip = { "Sound", { "card flip sound", "card sound" }, { "card" } },
		Hit = { "Sound", { "punch hit sound", "hit sound effect" }, { "hit", "punch" } },
		Victory = { "Sound", { "victory sound", "win fanfare" }, { "victory", "win" } },
	},
	Icons = {
		Money = { "Decal", { "money icon", "cash icon" }, { "money", "cash" } },
		Gem = { "Decal", { "gem icon", "diamond icon" }, { "gem", "diamond" } },
		Dice = { "Decal", { "dice icon" }, { "dice" } },
		Backpack = { "Decal", { "backpack icon", "inventory icon" }, { "backpack", "inventory" } },
		Tower = { "Decal", { "tower icon" }, { "tower" } },
		Index = { "Decal", { "book icon", "index icon" }, { "book", "index" } },
	},
}

local MAX_RESULTADOS = 10

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

local function semScripts(obj)
	for _, d in obj:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	return obj
end

local function nomeBate(nome, palavras)
	nome = string.lower(nome)
	for _, palavra in palavras do
		if string.find(nome, palavra, 1, true) then
			return true
		end
	end
	return false
end

-- Devolve o objeto a guardar a partir do que foi baixado (ou nil se não serve)
local function extrair(objetos, tipo)
	for _, obj in objetos do
		if tipo == "Model" then
			if obj:IsA("BasePart") or (obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart", true)) then
				return obj
			end
		elseif tipo == "ParticleEmitter" then
			if obj:IsA("ParticleEmitter") or obj:FindFirstChildWhichIsA("ParticleEmitter", true) then
				return obj
			end
		elseif obj:IsA(tipo) then
			return obj
		else
			local achado = obj:FindFirstChildWhichIsA(tipo, true)
			if achado then
				return achado
			end
		end
	end
	return nil
end

local raiz = pasta(ReplicatedStorage, "Assets")
local ok, falhas = 0, 0

for categoria, itens in BUSCAS do
	local destino = pasta(raiz, categoria)
	for nome, info in itens do
		local tipo, buscas, palavras = info[1], info[2], info[3]
		if destino:FindFirstChild(nome) then
			continue
		end
		local achou = false
		for _, busca in buscas do
			local sucesso, resultados = pcall(function()
				local paginas = if tipo == "Decal"
					then InsertService:GetFreeDecals(busca, 0)
					else InsertService:GetFreeModels(busca, 0)
				return paginas[1] and paginas[1].Results or {}
			end)
			for i = 1, if sucesso then math.min(#resultados, MAX_RESULTADOS) else 0 do
				local r = resultados[i]
				if nomeBate(r.Name, palavras) then
					local baixou, objetos = pcall(game.GetObjects, game, "rbxassetid://" .. r.AssetId)
					local item = baixou and extrair(objetos, tipo)
					if item then
						item = semScripts(item:Clone())
						item.Name = nome
						item.Parent = destino
						print(`[OK] {categoria}/{nome} <- "{r.Name}" (asset {r.AssetId}, criador {r.Creator or "?"})`)
						achou = true
						break
					end
				end
			end
			if achou then
				break
			end
		end
		if achou then
			ok += 1
		else
			falhas += 1
			warn(`[FALHOU] {categoria}/{nome}: nada encontrado; troque as buscas`)
		end
	end
end

print(`Pronto! {ok} adicionados, {falhas} falhas. Revise em ReplicatedStorage > Assets.`)
