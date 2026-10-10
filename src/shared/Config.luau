-- Balanceamento do jogo. Ajuste os valores aqui para mudar a economia.
-- Para usar modelos da Toolbox/Store, veja a seção "Modelos" no README.
local Config = {}

Config.StartingData = {
	Armadura = 0,
	Vitorias = 0,
	VitoriasTotais = 0, -- usado no ranking (não diminui quando você gasta)
	Nivel = 1,
	XP = 0,
	Rebirths = 0,
	Tutorial = 1,
	TutorialProgresso = 0,
	EscudoEquipado = "Madeira",
	Escudos = { Madeira = true },
	Pets = {}, -- lista de { Id = string, Tipo = string, Dourado = boolean }
	PetsEquipados = {}, -- lista de Ids
	ProximoPetId = 1,
	Auras = {},
	AuraEquipada = "",
	Mundo = 1,
	MundoMax = 1,
	Pocoes = { Armadura = 0, Vitorias = 0, Sorte = 0 },
	Boosts = { Armadura = 0, Vitorias = 0, Sorte = 0 }, -- os.time() até quando a poção vale
	BoostCompradoMult = 1,
	BoostCompradoAte = 0,
	Melhorias = { Slots = 0, Velocidade = 0, Armadura = 0, Vitorias = 0 },
	UltimaDiaria = 0,
	SequenciaDiaria = 0,
	UltimoLogin = 0,
}

-- No Studio, libera todos os gamepasses para você testar sem comprar
Config.LiberarPassesNoStudio = true

Config.VelocidadeBase = 25
Config.VelocidadeGamepass = 15

Config.ClickCooldown = 0.08
Config.AutoClickIntervalo = 0.3
Config.AutoClickOPIntervalo = 0.1

Config.OfflineCliquesPorMinuto = 10
Config.OfflineMaxMinutos = 8 * 60

Config.BonusPorNivel = 0.06
Config.BonusPorRebirth = 0.5

-- Escudos: Custo em vitórias, Bonus = armadura por toque
Config.Escudos = {
	{ Id = "Madeira", Nome = "Escudo Redondo de Madeira", Custo = 0, Bonus = 1, Cor = Color3.fromRGB(150, 100, 60) },
	{ Id = "Pedra", Nome = "Escudo de Pedra", Custo = 25, Bonus = 2, Cor = Color3.fromRGB(130, 130, 130) },
	{ Id = "Ferro", Nome = "Escudo de Ferro", Custo = 150, Bonus = 4, Cor = Color3.fromRGB(190, 195, 205) },
	{ Id = "Cavaleiro", Nome = "Escudo de Cavaleiro Alado", Custo = 500, Bonus = 8, Cor = Color3.fromRGB(90, 160, 255) },
	{ Id = "Dragao", Nome = "Escudo de Dragão Encantado", Custo = 1000, Bonus = 15, Cor = Color3.fromRGB(80, 200, 120) },
	{ Id = "Ouro", Nome = "Escudo de Ouro", Custo = 5000, Bonus = 35, Cor = Color3.fromRGB(255, 200, 40) },
	{ Id = "Diamante", Nome = "Escudo de Diamante", Custo = 25000, Bonus = 80, Cor = Color3.fromRGB(120, 230, 255) },
	{ Id = "Fogo", Nome = "Escudo Flamejante", Custo = 100000, Bonus = 200, Cor = Color3.fromRGB(255, 90, 30) },
	{ Id = "Cosmico", Nome = "Escudo Cósmico", Custo = 500000, Bonus = 500, Cor = Color3.fromRGB(170, 80, 255) },
	{ Id = "Gelo", Nome = "Escudo Glacial", Custo = 2500000, Bonus = 1300, Cor = Color3.fromRGB(180, 240, 255) },
	{ Id = "Magma", Nome = "Escudo de Magma", Custo = 15000000, Bonus = 3500, Cor = Color3.fromRGB(200, 40, 20) },
	{ Id = "Galaxia", Nome = "Escudo Galáctico", Custo = 100000000, Bonus = 10000, Cor = Color3.fromRGB(60, 30, 140) },
}

-- Paredes de cada pista. Em cada mundo a Vida e as Vitorias são multiplicadas.
Config.Paredes = {
	{ Vida = 10, Vitorias = 2 },
	{ Vida = 100, Vitorias = 5 },
	{ Vida = 500, Vitorias = 15 },
	{ Vida = 2000, Vitorias = 40 },
	{ Vida = 10000, Vitorias = 100 },
	{ Vida = 50000, Vitorias = 250 },
	{ Vida = 250000, Vitorias = 600 },
	{ Vida = 1000000, Vitorias = 1500 },
	{ Vida = 5000000, Vitorias = 4000 },
	{ Vida = 25000000, Vitorias = 10000 },
}
Config.ParedeCooldown = 5

-- Mundos: Custo em vitórias para liberar. Cores = { chão 1, chão 2, grama 1, grama 2 }
Config.Mundos = {
	{
		Nome = "Mundo Grama",
		Custo = 0,
		MultVida = 1,
		MultVitorias = 1,
		Cores = {
			Color3.fromRGB(240, 240, 245),
			Color3.fromRGB(205, 200, 215),
			Color3.fromRGB(90, 210, 70),
			Color3.fromRGB(60, 180, 50),
		},
	},
	{
		Nome = "Mundo Neve",
		Custo = 25000,
		MultVida = 50,
		MultVitorias = 20,
		Cores = {
			Color3.fromRGB(235, 245, 255),
			Color3.fromRGB(200, 220, 245),
			Color3.fromRGB(150, 200, 255),
			Color3.fromRGB(110, 170, 240),
		},
	},
	{
		Nome = "Mundo Lava",
		Custo = 2000000,
		MultVida = 2500,
		MultVitorias = 400,
		Cores = {
			Color3.fromRGB(70, 60, 60),
			Color3.fromRGB(50, 40, 40),
			Color3.fromRGB(255, 110, 30),
			Color3.fromRGB(220, 60, 20),
		},
	},
	{
		Nome = "Mundo Doce",
		Custo = 150000000,
		MultVida = 120000,
		MultVitorias = 8000,
		Cores = {
			Color3.fromRGB(255, 230, 245),
			Color3.fromRGB(255, 200, 230),
			Color3.fromRGB(255, 120, 200),
			Color3.fromRGB(190, 120, 255),
		},
	},
}

-- Iluminação "cor viva" estilo simulator
Config.Visual = {
	Saturacao = 0.35,
	Contraste = 0.1,
	Brilho = 0.03,
}

Config.Pista = {
	Largura = 30,
	Espacamento = 35,
	AlturaParede = 14,
	TamanhoPiso = 6,
	DistanciaEntreMundos = 600, -- cada mundo fica deslocado no eixo X
	TamanhoHub = Vector3.new(96, 1, 72), -- área do spawn, ovos e rankings
}

-- Pets: Bonus = +% de armadura (0.1 = +10%). Raridade só muda a cor do texto.
Config.Raridades = {
	Comum = Color3.fromRGB(200, 200, 200),
	Raro = Color3.fromRGB(80, 160, 255),
	Epico = Color3.fromRGB(180, 80, 255),
	Lendario = Color3.fromRGB(255, 190, 40),
	Mitico = Color3.fromRGB(255, 60, 90),
}

Config.Pets = {
	Cachorro = { Nome = "Cachorro", Bonus = 0.1, Raridade = "Comum", Cor = Color3.fromRGB(170, 120, 70) },
	Gato = { Nome = "Gato", Bonus = 0.15, Raridade = "Comum", Cor = Color3.fromRGB(250, 160, 60) },
	Coelho = { Nome = "Coelho", Bonus = 0.25, Raridade = "Raro", Cor = Color3.fromRGB(240, 240, 240) },
	Raposa = { Nome = "Raposa", Bonus = 0.4, Raridade = "Raro", Cor = Color3.fromRGB(255, 120, 40) },
	Panda = { Nome = "Panda", Bonus = 0.6, Raridade = "Epico", Cor = Color3.fromRGB(60, 60, 60) },
	Unicornio = { Nome = "Unicórnio", Bonus = 1.2, Raridade = "Lendario", Cor = Color3.fromRGB(255, 170, 240) },
	Pinguim = { Nome = "Pinguim", Bonus = 2, Raridade = "Comum", Cor = Color3.fromRGB(40, 50, 70) },
	Urso = { Nome = "Urso Polar", Bonus = 3, Raridade = "Raro", Cor = Color3.fromRGB(235, 245, 255) },
	Yeti = { Nome = "Yeti", Bonus = 5, Raridade = "Epico", Cor = Color3.fromRGB(170, 220, 255) },
	Fenix = { Nome = "Fênix", Bonus = 10, Raridade = "Lendario", Cor = Color3.fromRGB(255, 90, 20) },
	Salamandra = { Nome = "Salamandra", Bonus = 15, Raridade = "Raro", Cor = Color3.fromRGB(230, 70, 30) },
	Golem = { Nome = "Golem de Lava", Bonus = 25, Raridade = "Epico", Cor = Color3.fromRGB(90, 40, 30) },
	Dragao = { Nome = "Dragão", Bonus = 50, Raridade = "Mitico", Cor = Color3.fromRGB(200, 30, 50) },
	Ursinho = { Nome = "Ursinho de Goma", Bonus = 80, Raridade = "Raro", Cor = Color3.fromRGB(255, 80, 120) },
	Cupcake = { Nome = "Cupcake", Bonus = 130, Raridade = "Epico", Cor = Color3.fromRGB(255, 190, 220) },
	Arcoiris = { Nome = "Gato Arco-íris", Bonus = 300, Raridade = "Mitico", Cor = Color3.fromRGB(120, 255, 200) },
}

-- Ovos: Custo em vitórias. Chance em %, a soma de cada ovo deve dar 100.
Config.Ovos = {
	{
		Id = "Basico",
		Nome = "Ovo Básico",
		Mundo = 1,
		Custo = 50,
		Cor = Color3.fromRGB(240, 230, 200),
		Pets = {
			{ Pet = "Cachorro", Chance = 55 },
			{ Pet = "Gato", Chance = 35 },
			{ Pet = "Coelho", Chance = 9 },
			{ Pet = "Unicornio", Chance = 1 },
		},
	},
	{
		Id = "Floresta",
		Nome = "Ovo da Floresta",
		Mundo = 1,
		Custo = 1000,
		Cor = Color3.fromRGB(110, 200, 90),
		Pets = {
			{ Pet = "Coelho", Chance = 50 },
			{ Pet = "Raposa", Chance = 35 },
			{ Pet = "Panda", Chance = 13 },
			{ Pet = "Unicornio", Chance = 2 },
		},
	},
	{
		Id = "Neve",
		Nome = "Ovo de Neve",
		Mundo = 2,
		Custo = 50000,
		Cor = Color3.fromRGB(190, 230, 255),
		Pets = {
			{ Pet = "Pinguim", Chance = 55 },
			{ Pet = "Urso", Chance = 32 },
			{ Pet = "Yeti", Chance = 12 },
			{ Pet = "Fenix", Chance = 1 },
		},
	},
	{
		Id = "Lava",
		Nome = "Ovo de Lava",
		Mundo = 3,
		Custo = 5000000,
		Cor = Color3.fromRGB(255, 100, 30),
		Pets = {
			{ Pet = "Salamandra", Chance = 60 },
			{ Pet = "Golem", Chance = 35 },
			{ Pet = "Dragao", Chance = 5 },
		},
	},
	{
		Id = "Doce",
		Nome = "Ovo Doce",
		Mundo = 4,
		Custo = 400000000,
		Cor = Color3.fromRGB(255, 160, 220),
		Pets = {
			{ Pet = "Ursinho", Chance = 60 },
			{ Pet = "Cupcake", Chance = 36 },
			{ Pet = "Arcoiris", Chance = 4 },
		},
	},
}

Config.PetsEquipadosBase = 3
Config.MaxPets = 60
Config.FusaoQuantidade = 5 -- quantos pets iguais viram 1 dourado
Config.MultDourado = 3 -- pet dourado tem o bônus multiplicado por isso

-- Auras: Bonus = +% de vitórias. Custo em vitórias.
Config.Auras = {
	{ Id = "Faisca", Nome = "Aura de Faísca", Custo = 2000, Bonus = 0.25, Cor = Color3.fromRGB(255, 240, 120) },
	{ Id = "Gelo", Nome = "Aura de Gelo", Custo = 40000, Bonus = 0.6, Cor = Color3.fromRGB(140, 220, 255) },
	{ Id = "Fogo", Nome = "Aura de Fogo", Custo = 800000, Bonus = 1.2, Cor = Color3.fromRGB(255, 100, 30) },
	{ Id = "Veneno", Nome = "Aura Tóxica", Custo = 20000000, Bonus = 2.5, Cor = Color3.fromRGB(120, 255, 60) },
	{ Id = "Galaxia", Nome = "Aura Galáctica", Custo = 500000000, Bonus = 5, Cor = Color3.fromRGB(170, 90, 255) },
}

-- Melhorias permanentes (compradas com vitórias). Custo = CustoBase * Crescimento ^ nível
Config.Melhorias = {
	{ Id = "Armadura", Nome = "+10% Armadura", CustoBase = 300, Crescimento = 2.2, Max = 25 },
	{ Id = "Vitorias", Nome = "+10% Vitórias", CustoBase = 500, Crescimento = 2.3, Max = 25 },
	{ Id = "Velocidade", Nome = "+2 Velocidade", CustoBase = 200, Crescimento = 2, Max = 10 },
	{ Id = "Slots", Nome = "+1 Pet equipado", CustoBase = 2500, Crescimento = 6, Max = 5 },
}

-- Poções: duram Minutos e multiplicam por Mult. "Sorte" aumenta a chance de pets raros.
Config.Pocoes = {
	Armadura = { Nome = "Poção de Armadura", Mult = 2, Minutos = 10, Cor = Color3.fromRGB(255, 80, 80) },
	Vitorias = { Nome = "Poção de Vitórias", Mult = 2, Minutos = 10, Cor = Color3.fromRGB(255, 210, 50) },
	Sorte = { Nome = "Poção da Sorte", Mult = 2, Minutos = 10, Cor = Color3.fromRGB(90, 230, 110) },
}

-- Recompensa: { Tipo = "Vitorias"|"Armadura"|"Pocao"|"Ovo", Qtd = n, Pocao = id, Ovo = id }
Config.Diarias = {
	{ Tipo = "Vitorias", Qtd = 50 },
	{ Tipo = "Pocao", Pocao = "Armadura", Qtd = 1 },
	{ Tipo = "Vitorias", Qtd = 200 },
	{ Tipo = "Pocao", Pocao = "Sorte", Qtd = 1 },
	{ Tipo = "Ovo", Ovo = "Floresta", Qtd = 1 },
	{ Tipo = "Pocao", Pocao = "Vitorias", Qtd = 2 },
	{ Tipo = "Vitorias", Qtd = 2000 },
}

-- Presentes por tempo jogado na sessão (minutos)
Config.Presentes = {
	{ Minutos = 1, Recompensa = { Tipo = "Vitorias", Qtd = 20 } },
	{ Minutos = 5, Recompensa = { Tipo = "Pocao", Pocao = "Armadura", Qtd = 1 } },
	{ Minutos = 10, Recompensa = { Tipo = "Ovo", Ovo = "Basico", Qtd = 1 } },
	{ Minutos = 15, Recompensa = { Tipo = "Vitorias", Qtd = 150 } },
	{ Minutos = 25, Recompensa = { Tipo = "Pocao", Pocao = "Vitorias", Qtd = 1 } },
	{ Minutos = 40, Recompensa = { Tipo = "Pocao", Pocao = "Sorte", Qtd = 1 } },
	{ Minutos = 60, Recompensa = { Tipo = "Ovo", Ovo = "Floresta", Qtd = 1 } },
}

Config.VitoriasAutoIntervalo = 10 -- segundos entre cada "parede automática"

Config.Tutorial = {
	{ Texto = "Toque para ficar mais forte!", Tipo = "Clique", Meta = 10, Unidade = "cliques" },
	{ Texto = "Corra pela pista e quebre uma parede!", Tipo = "Parede", Meta = 1, Unidade = "paredes" },
	{ Texto = "Chegue ao nível 2!", Tipo = "Nivel", Meta = 2, Unidade = "nível", Absoluto = true },
	{ Texto = "Compre um escudo novo!", Tipo = "Escudo", Meta = 1, Unidade = "escudos" },
	{ Texto = "Abra um ovo e ganhe um pet!", Tipo = "Ovo", Meta = 1, Unidade = "ovos" },
	{ Texto = "Chegue ao nível 5!", Tipo = "Nivel", Meta = 5, Unidade = "nível", Absoluto = true },
}
Config.TutorialRecompensa = 20

-- IDs dos gamepasses do Creator Hub (0 = não configurado)
Config.Gamepasses = {
	DobroArmadura = { Id = 0, Nome = "x2 Armadura" },
	DobroVitorias = { Id = 0, Nome = "x2 Vitórias" },
	Velocidade = { Id = 0, Nome = "+15 Velocidade" },
	AutoClickOP = { Id = 0, Nome = "Autoclic OP" },
	VitoriasAuto = { Id = 0, Nome = "Vitórias Automáticas" },
	PetsExtra = { Id = 0, Nome = "+3 Pets equipados" },
}

-- IDs dos Developer Products (boosts de armadura comprados com Robux)
Config.Produtos = {
	{ Id = 0, Nome = "x2 Armadura (15 min)", Mult = 2, Minutos = 15 },
	{ Id = 0, Nome = "x4 Armadura (15 min)", Mult = 4, Minutos = 15 },
	{ Id = 0, Nome = "x8 Armadura (15 min)", Mult = 8, Minutos = 15 },
}

---------------------------------------------------------------------------------
-- Funções auxiliares (usadas pelo servidor e pelo cliente)

local function buscar(lista, id)
	for _, item in lista do
		if item.Id == id then
			return item
		end
	end
	return nil
end

function Config.getEscudo(id: string)
	return buscar(Config.Escudos, id)
end

function Config.getOvo(id: string)
	return buscar(Config.Ovos, id)
end

function Config.getAura(id: string)
	return buscar(Config.Auras, id)
end

function Config.getMelhoria(id: string)
	return buscar(Config.Melhorias, id)
end

function Config.xpParaNivel(nivel: number): number
	return 100 * nivel
end

function Config.nivelParaRebirth(rebirths: number): number
	return 10 * (rebirths + 1)
end

function Config.custoMelhoria(id: string, nivel: number): number
	local melhoria = Config.getMelhoria(id)
	return math.floor(melhoria.CustoBase * melhoria.Crescimento ^ nivel)
end

function Config.bonusPet(tipo: string, dourado: boolean): number
	local pet = Config.Pets[tipo]
	if not pet then
		return 0
	end
	return if dourado then pet.Bonus * Config.MultDourado else pet.Bonus
end

function Config.origemMundo(mundo: number): Vector3
	return Vector3.new((mundo - 1) * Config.Pista.DistanciaEntreMundos, 0, 0)
end

function Config.copiar(valor)
	if typeof(valor) ~= "table" then
		return valor
	end
	local copia = {}
	for k, v in valor do
		copia[k] = Config.copiar(v)
	end
	return copia
end

function Config.descreverRecompensa(r): string
	if r.Tipo == "Vitorias" then
		return `🏆 {r.Qtd} Vitórias`
	elseif r.Tipo == "Armadura" then
		return `🛡️ {r.Qtd} Armadura`
	elseif r.Tipo == "Pocao" then
		return `🧪 {r.Qtd}x {Config.Pocoes[r.Pocao].Nome}`
	elseif r.Tipo == "Ovo" then
		return `🥚 {Config.getOvo(r.Ovo).Nome} grátis`
	end
	return "?"
end

return Config
