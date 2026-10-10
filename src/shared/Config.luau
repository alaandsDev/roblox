-- Balanceamento do jogo. Ajuste os valores aqui para mudar a economia.
local Config = {}

Config.StartingData = {
	Armadura = 0,
	Vitorias = 0,
	Nivel = 1,
	XP = 0,
	Rebirths = 0,
	Tutorial = 1,
	TutorialProgresso = 0,
	EscudoEquipado = "Madeira",
	Escudos = { Madeira = true },
	UltimoLogin = 0,
}

Config.VelocidadeBase = 25
Config.VelocidadeGamepass = 15

-- Tempo mínimo (segundos) entre cliques aceitos pelo servidor
Config.ClickCooldown = 0.08
Config.AutoClickIntervalo = 0.3
Config.AutoClickOPIntervalo = 0.1

-- Ganho offline: equivale a N cliques por minuto fora do jogo, até o limite de minutos
Config.OfflineCliquesPorMinuto = 10
Config.OfflineMaxMinutos = 8 * 60

Config.BonusPorNivel = 0.06 -- +6% de armadura por nível
Config.BonusPorRebirth = 0.5 -- +50% de armadura por rebirth

-- Escudos: Custo em vitórias, Bonus = armadura ganha por clique
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
}

-- Paredes da pista: precisa de Vida de armadura para atravessar; dá Vitorias ao quebrar
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
Config.ParedeCooldown = 5 -- segundos até a mesma parede dar vitórias de novo

Config.Pista = {
	Origem = Vector3.new(0, 0, 40), -- onde a pista começa
	Largura = 30,
	Espacamento = 35, -- distância entre paredes
	AlturaParede = 14,
	TamanhoPiso = 6, -- tamanho de cada quadrado do chão
	CoresPiso = { Color3.fromRGB(240, 240, 245), Color3.fromRGB(205, 200, 215) },
}

-- Iluminação "cor viva" estilo simulator
Config.Visual = {
	Saturacao = 0.35,
	Contraste = 0.1,
	Brilho = 0.03,
}

-- Absoluto = o progresso é o valor atual (nível, vitórias); senão é um contador
Config.Tutorial = {
	{ Texto = "Toque para ficar mais forte!", Tipo = "Clique", Meta = 10, Unidade = "cliques" },
	{ Texto = "Corra pela pista e quebre uma parede!", Tipo = "Parede", Meta = 1, Unidade = "paredes" },
	{ Texto = "Chegue ao nível 2!", Tipo = "Nivel", Meta = 2, Unidade = "nível", Absoluto = true },
	{ Texto = "Compre um escudo novo!", Tipo = "Escudo", Meta = 1, Unidade = "escudos" },
	{ Texto = "Junte 100 vitórias!", Tipo = "Vitorias", Meta = 100, Unidade = "vitórias", Absoluto = true },
	{ Texto = "Chegue ao nível 5!", Tipo = "Nivel", Meta = 5, Unidade = "nível", Absoluto = true },
}
Config.TutorialRecompensa = 10 -- vitórias por passo concluído

-- Coloque os IDs dos gamepasses criados no Creator Hub (0 = não configurado)
Config.Gamepasses = {
	DobroArmadura = { Id = 0, Nome = "x2 Armadura" },
	DobroVitorias = { Id = 0, Nome = "x2 Vitórias" },
	Velocidade = { Id = 0, Nome = "+15 Velocidade" },
	AutoClickOP = { Id = 0, Nome = "Autoclic OP" },
}

function Config.getEscudo(id: string)
	for _, escudo in Config.Escudos do
		if escudo.Id == id then
			return escudo
		end
	end
	return nil
end

function Config.xpParaNivel(nivel: number): number
	return 100 * nivel
end

function Config.multiplicador(nivel: number, rebirths: number, dobro: boolean?): number
	local mult = (1 + nivel * Config.BonusPorNivel) * (1 + rebirths * Config.BonusPorRebirth)
	return if dobro then mult * 2 else mult
end

function Config.ganhoPorClique(escudoId: string, nivel: number, rebirths: number, dobro: boolean?): number
	local escudo = Config.getEscudo(escudoId) or Config.Escudos[1]
	return math.max(1, math.floor(escudo.Bonus * Config.multiplicador(nivel, rebirths, dobro)))
end

-- Nível mínimo para renascer
function Config.nivelParaRebirth(rebirths: number): number
	return 10 * (rebirths + 1)
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

return Config
