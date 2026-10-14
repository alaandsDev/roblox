--!strict
--[[
	AURAS V2 — composição por ZONAS (não "mais partículas").
	    RARIDADE = intensidade/complexidade: nº de camadas COORDENADAS, alcance (silhueta), movimento
	    ESTILO   = identidade: paleta (clara + ESCURA para contraste), textura, direção e um
	               elemento ASSINATURA reconhecível (raio, chama, fragmentos, estrelas...)

	Por que a V1 sumia no mapa claro/saturado: mistura aditiva (LightEmission 0,7–1) com texturas
	brancas e suaves "lavava" para branco sobre céu/chão claro; partículas de 0,2–0,5 stud com vida
	de 0,35 s (≈3 vivas por camada no Light) e TUDO nascendo dentro do volume do corpo (o próprio
	personagem escondia a aura; nada passava da silhueta).

	V2 (montada pelo AuraBuilder, animada pelo AuraController num loop central):
	    ZONAS   Inner = no corpo · Mid = ~2–4 studs · Outer = ~4–7 studs
	    CONTRASTE camadas principais com mistura ALFA (LightEmission baixo: a cor fica saturada
	              sobre fundo claro) + camada ESCURA/funda atrás do corpo; só faíscas/raios brilham
	    LEITURA  partículas maiores e mais opacas, vida longa, formas (streaks, anéis, fragmentos)
	    SILHUETA Silhouette = altura/largura visual ÷ personagem (Lendário 1,2 → Secreto 2,5)
	    CONTORNO Highlight (contorno na cor do estilo) a partir do Mítico — orçamento central
	PointLight continua só complemento.
	Texturas: só as nativas do Roblox (rbxasset://). O Auras Pack NÃO é usado (auditoria do pack
	real ainda pendente: nada dele passou pela verificação de segurança/proveniência).
]]

local AuraConfig = {}

AuraConfig.Textures = {
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Ember = "rbxasset://textures/particles/fire_sparks_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
}

-- Zonas (studs a partir do eixo do corpo). Outer cresce com a raridade (ver Tier.Silhouette).
AuraConfig.Zones = { MidMin = 2, MidMax = 4, OuterMin = 4, OuterMax = 7 }

export type Tier = {
	Silhouette: number, -- tamanho visual ÷ personagem (altura e largura da composição)
	Layers: { string }, -- camadas COORDENADAS (ordem de montagem); ver AuraPlanner.Kinds
	Orbiters: number,
	Rate: number, -- escala de densidade (multiplica as taxas base de cada camada)
	SignatureCount: number, -- quantos elementos de assinatura (raios, fitas, chamas...)
	PulseEvery: number?, -- pulso/shockwave periódico (s); o cliente varia ±25% (nada sincronizado)
	Highlight: boolean, -- contorno de silhueta (Highlight)
	Glow: number, -- PointLight complementar
}

-- Lendário 3 · Mítico 5 · Divino 8 · Secreto 11 camadas
AuraConfig.Tiers = {
	Legendary = {
		Silhouette = 1.2,
		Layers = { "Body", "Rise", "Signature" },
		Orbiters = 0,
		Rate = 1,
		SignatureCount = 2,
		PulseEvery = nil,
		Highlight = false,
		Glow = 0.4,
	},
	Mythic = {
		Silhouette = 1.5,
		Layers = { "Body", "Rise", "Orbit", "Signature", "Pulse" },
		Orbiters = 2,
		Rate = 1.25,
		SignatureCount = 3,
		PulseEvery = 4,
		Highlight = true,
		Glow = 0.6,
	},
	Divine = {
		Silhouette = 2.0,
		Layers = { "Body", "Depth", "Rise", "Orbit", "Ribbon", "Ground", "Shockwave", "Signature" },
		Orbiters = 3,
		Rate = 1.5,
		SignatureCount = 4,
		PulseEvery = 3.2,
		Highlight = true,
		Glow = 0.8,
	},
	Secret = {
		Silhouette = 2.5,
		Layers = { "Body", "Contrast", "Depth", "Rise", "Outer", "Orbit", "Ribbon", "Ground", "Shockwave", "Signature", "Crown" },
		Orbiters = 4,
		Rate = 1.7,
		SignatureCount = 6,
		PulseEvery = 2.6,
		Highlight = true,
		Glow = 1,
	},
} :: { [string]: Tier }

--[[
	Light (Base/Torre): MESMA identidade (todas as camadas e a assinatura), menos partículas e
	menos órbitas. Full (reveal/hero/galeria): versão cinematográfica completa.
	Light NÃO é "quase invisível": tamanho, opacidade e alcance são os mesmos do Full.
]]
AuraConfig.LightScale = { Rate = 0.55, Orbits = 0.5, Signature = 0.75, Pulse = true, Ground = true }

export type Style = {
	Colors: { { number } }, -- principal, clara, destaque
	Dark: { number }, -- tom ESCURO do estilo (contraste sobre fundo claro)
	Texture: string, -- textura do corpo (chave de Textures)
	Direction: string, -- "Up" | "Out" | "In" | "Swirl" | "Down"
	Speed: number,
	Lifetime: number,
	Size: number, -- tamanho base das partículas do corpo (studs)
	Streak: boolean,
	Signature: string, -- elemento assinatura (AuraBuilder.Signatures)
	OrbitSpeed: number, -- rad/s
	OrbitWobble: number, -- 0 = órbita regular; >0 = irregular (Void/Gravity)
	Drag: number,
}

AuraConfig.Styles = {
	Electric = { Colors = { { 90, 170, 255 }, { 225, 245, 255 }, { 255, 240, 90 } }, Dark = { 20, 40, 120 }, Texture = "Spark", Direction = "Out", Speed = 5, Lifetime = 0.7, Size = 1.1, Streak = true, Signature = "Lightning", OrbitSpeed = 6, OrbitWobble = 0, Drag = 1.5 },
	Flame = { Colors = { { 255, 110, 20 }, { 255, 225, 80 }, { 220, 30, 10 } }, Dark = { 110, 20, 5 }, Texture = "Fire", Direction = "Up", Speed = 5, Lifetime = 1, Size = 1.6, Streak = false, Signature = "Flames", OrbitSpeed = 3, OrbitWobble = 0, Drag = 0.8 },
	Void = { Colors = { { 140, 50, 230 }, { 230, 170, 255 }, { 40, 0, 80 } }, Dark = { 15, 0, 35 }, Texture = "Smoke", Direction = "In", Speed = 3, Lifetime = 1.3, Size = 1.6, Streak = false, Signature = "Fragments", OrbitSpeed = 2.2, OrbitWobble = 0.6, Drag = 0.5 },
	Dark = { Colors = { { 120, 20, 50 }, { 255, 70, 90 }, { 30, 10, 30 } }, Dark = { 10, 5, 12 }, Texture = "Smoke", Direction = "Up", Speed = 3.2, Lifetime = 1.3, Size = 1.7, Streak = false, Signature = "Shadows", OrbitSpeed = 2.5, OrbitWobble = 0.3, Drag = 0.6 },
	Celestial = { Colors = { { 255, 215, 90 }, { 255, 255, 255 }, { 120, 200, 255 } }, Dark = { 150, 100, 20 }, Texture = "Spark", Direction = "Up", Speed = 3.5, Lifetime = 1.4, Size = 1.2, Streak = false, Signature = "Stars", OrbitSpeed = 1.8, OrbitWobble = 0, Drag = 0.8 },
	Wind = { Colors = { { 60, 220, 160 }, { 230, 255, 245 }, { 20, 140, 120 } }, Dark = { 10, 70, 60 }, Texture = "Smoke", Direction = "Swirl", Speed = 7, Lifetime = 0.9, Size = 1.2, Streak = true, Signature = "Gusts", OrbitSpeed = 7, OrbitWobble = 0, Drag = 1.2 },
	Ice = { Colors = { { 120, 210, 255 }, { 245, 255, 255 }, { 40, 110, 220 } }, Dark = { 15, 45, 110 }, Texture = "Spark", Direction = "Down", Speed = 2.5, Lifetime = 1.3, Size = 1.1, Streak = false, Signature = "Shards", OrbitSpeed = 2.4, OrbitWobble = 0, Drag = 1 },
	Energy = { Colors = { { 255, 60, 190 }, { 255, 220, 255 }, { 130, 60, 255 } }, Dark = { 70, 10, 90 }, Texture = "Spark", Direction = "Out", Speed = 4.5, Lifetime = 0.9, Size = 1.2, Streak = true, Signature = "Rings", OrbitSpeed = 4, OrbitWobble = 0, Drag = 1.2 },
	Spirit = { Colors = { { 70, 230, 210 }, { 220, 255, 250 }, { 40, 140, 255 } }, Dark = { 10, 70, 90 }, Texture = "Smoke", Direction = "Up", Speed = 2.2, Lifetime = 1.8, Size = 1.4, Streak = false, Signature = "Wisps", OrbitSpeed = 1.6, OrbitWobble = 0.2, Drag = 0.4 },
	Gravity = { Colors = { { 150, 80, 255 }, { 255, 200, 90 }, { 60, 25, 130 } }, Dark = { 25, 10, 60 }, Texture = "Ember", Direction = "In", Speed = 4, Lifetime = 1.1, Size = 1.1, Streak = true, Signature = "Pull", OrbitSpeed = 3.2, OrbitWobble = 0.5, Drag = 0.7 },
} :: { [string]: Style }

-- Estilo pelo Dice de origem (tema do pool); personagens específicos podem sobrescrever
AuraConfig.StyleByDice = {
	Starter = "Energy",
	Lucky = "Energy",
	Rampart = "Gravity",
	Shinobi = "Wind",
	Flame = "Flame",
	Blade = "Wind",
	Fighter = "Energy",
	Storm = "Electric",
	Spirit = "Spirit",
	Arcane = "Energy",
	Shadow = "Dark",
	Void = "Void",
	Colossus = "Gravity",
	Awakened = "Energy",
	Celestial = "Celestial",
	Forbidden = "Void",
}

-- Overrides por personagem (prefixo do id): o elétrico de referência (Killuo) e afins
AuraConfig.StyleByCharacterPrefix = {
	{ Prefix = "char_killuo", Style = "Electric" },
	{ Prefix = "char_todoruki", Style = "Ice" },
	{ Prefix = "char_goko", Style = "Electric" },
	{ Prefix = "char_kaulifa", Style = "Energy" },
	{ Prefix = "char_hizoka", Style = "Dark" },
}

AuraConfig.DefaultStyle = "Energy"

-- ORÇAMENTO de performance (cliente: AuraController; testes: tests/Aura.spec.luau + harnesses)
AuraConfig.Budget = {
	-- além disso o cliente desliga as partículas da aura (studs da câmera)
	CullDistance = 110,
	-- a partir daqui as auras animadas caem para metade da taxa (mesma identidade)
	MidDistance = 55,
	-- auras com animação (órbita/raio/pulso) ao mesmo tempo: as mais próximas da câmera
	MaxAnimated = 10,
	-- auras FULL simultâneas (reveal/hero/galeria); as outras ficam Light
	MaxFull = 3,
	-- contornos (Highlight) simultâneos — o Roblox desenha no máximo 31 por tela
	MaxHighlights = 10,
	-- loop central do cliente (Hz)
	UpdateRate = 30,
	-- mobile / qualidade baixa: fator nas taxas de emissão
	LowEndRateScale = 0.5,
	-- teto de partículas/s somadas de UMA aura Full e de partículas VIVAS (taxa × vida)
	MaxRatePerAura = 260,
	MaxAlivePerAura = 340,
	-- teto de Instances criadas por UMA aura (emissores, beams, attachments, partes...)
	MaxInstancesPerAura = 90,
}

return AuraConfig
