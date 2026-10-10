--[[
	Busca SONS, CÉU, EFEITOS e ÍCONES grátis na Creator Store e coloca em ReplicatedStorage.Modelos.

	COMO USAR (igual ao BuscarModelos.lua):
	1. No Studio: Janela > Barra de comandos.
	2. Copie TODO este arquivo, cole na barra e aperte Enter UMA vez.
	3. Acompanhe na janela Saída. Itens que já existem são pulados (pode rodar de novo).
	4. Teste com Play. Depois salve a pasta Modelos de novo em assets\Modelos.rbxm.

	Cada item tenta as buscas na ordem e pega o primeiro resultado válido
	(som tem Sound, céu tem Sky, efeito tem ParticleEmitter, ícone é imagem).
	Não gostou de algum? Apague da pasta e troque as palavras de busca, ou coloque um seu
	com o mesmo nome.
]]

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SONS = {
	Clique = { "click sound effect", "pop sound", "button click" },
	Ovo = { "egg hatch sound", "pet hatch sound", "reveal sound" },
	Nivel = { "level up sound", "level up" },
	Compra = { "purchase sound", "cash register sound", "coin sound" },
	Parede = { "break sound", "smash sound", "punch sound" },
	Rebirth = { "magic sound", "rebirth sound", "power up sound" },
	Musica = { "upbeat music", "happy music", "simulator music" },
}

local EFEITOS = {
	Parede = { "explosion particle", "hit effect", "impact vfx" },
	Compra = { "sparkle particle", "sparkles effect" },
	Rebirth = { "rainbow particle", "confetti particle", "magic particle" },
	Nivel = { "level up effect", "level up particle", "glow particle" },
	Ovo = { "hatch effect", "star particle" },
}

local CEU = { "cartoon sky", "anime skybox", "cartoon skybox", "bright sky" }

-- Todos com o mesmo estilo de busca para os ícones combinarem entre si
local ICONES = {
	Vitoria = { "simulator trophy icon", "trophy icon", "trophy", "wins icon" },
	Rebirth = { "simulator rebirth icon", "rebirth icon", "rebirth" },
	Escudo = { "simulator shield icon", "shield icon", "shield" },
	Pet = { "simulator pet icon", "paw icon", "pet icon" },
	Fusao = { "simulator fuse icon", "fuse icon", "fusion icon", "merge icon" },
	Melhoria = { "simulator upgrade icon", "upgrade icon", "upgrade arrow", "upgrades" },
	Aura = { "simulator aura icon", "aura icon", "sparkle icon" },
	Mundo = { "simulator world icon", "world icon", "globe icon", "planet icon" },
	Pocao = { "simulator potion icon", "potion icon", "potion" },
	Presente = { "simulator gift icon", "gift icon", "rewards icon", "present icon" },
}

-- O nome da imagem precisa ter uma destas palavras (a busca de imagens traz muito lixo)
local PALAVRAS_ICONE = {
	Vitoria = { "troph", "win", "cup" },
	Rebirth = { "rebirth" },
	Escudo = { "shield" },
	Pet = { "pet", "paw" },
	Fusao = { "fuse", "fusion", "merge" },
	Melhoria = { "upgrade" },
	Aura = { "aura", "sparkle" },
	Mundo = { "world", "globe", "planet", "earth" },
	Pocao = { "potion" },
	Presente = { "gift", "reward", "present" },
}

local function nomeTem(nome, palavras)
	nome = string.lower(nome)
	for _, palavra in palavras do
		if string.find(nome, palavra, 1, true) then
			return true
		end
	end
	return false
end

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

local function primeiroDe(objetos, classe)
	for _, obj in objetos do
		if obj:IsA(classe) then
			return obj
		end
		local achado = obj:FindFirstChildWhichIsA(classe, true)
		if achado then
			return achado
		end
	end
	return nil
end

local ok, falhas = 0, 0

-- Tenta cada busca; "validar" recebe os objetos baixados e o nome do resultado,
-- e devolve o que guardar (ou nil)
local function buscar(destino, nome, consultas, decal, validar)
	if destino:FindFirstChild(nome) then
		return
	end
	for _, consulta in consultas do
		local sucesso, resultados = pcall(function()
			local paginas = if decal
				then InsertService:GetFreeDecals(consulta, 0)
				else InsertService:GetFreeModels(consulta, 0)
			return paginas[1] and paginas[1].Results or {}
		end)
		if sucesso then
			for i = 1, math.min(#resultados, 8) do
				local r = resultados[i]
				local baixou, objetos = pcall(game.GetObjects, game, "rbxassetid://" .. r.AssetId)
				if baixou then
					local guardar = validar(objetos, r.Name)
					if guardar then
						guardar = semScripts(guardar:Clone())
						guardar.Name = nome
						guardar.Parent = destino
						print(`[OK] {destino.Name}/{nome} <- "{r.Name}" (asset {r.AssetId})`)
						ok += 1
						return
					end
				end
			end
		end
	end
	falhas += 1
	warn(`[FALHOU] {destino.Name}/{nome}: nada válido encontrado; troque as palavras de busca`)
end

local raiz = pasta(ReplicatedStorage, "Modelos")

local sons = pasta(raiz, "Sons")
for nome, consultas in SONS do
	buscar(sons, nome, consultas, false, function(objetos)
		return primeiroDe(objetos, "Sound")
	end)
end

local efeitos = pasta(raiz, "Efeitos")
for nome, consultas in EFEITOS do
	buscar(efeitos, nome, consultas, false, function(objetos)
		if not primeiroDe(objetos, "ParticleEmitter") then
			return nil
		end
		local modelo = Instance.new("Model")
		for _, obj in objetos do
			obj.Parent = modelo
		end
		return modelo
	end)
end

local ceu = pasta(raiz, "Ceu")
buscar(ceu, "Sky", CEU, false, function(objetos)
	return primeiroDe(objetos, "Sky")
end)

local icones = pasta(raiz, "Icones")
for nome, consultas in ICONES do
	buscar(icones, nome, consultas, true, function(objetos, nomeResultado)
		if not nomeTem(nomeResultado, PALAVRAS_ICONE[nome]) then
			return nil
		end
		local decal = primeiroDe(objetos, "Decal")
		return if decal and decal.Texture ~= "" then decal else nil
	end)
end

print(`Pronto! {ok} itens adicionados, {falhas} falhas. Confira em ReplicatedStorage > Modelos.`)
