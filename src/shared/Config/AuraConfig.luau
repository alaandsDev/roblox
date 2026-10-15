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
		Rate = 1.6,
		SignatureCount = 3,
		PulseEvery = nil,
		Highlight = false,
		Glow = 0.4,
	},
	Mythic = {
		Silhouette = 1.5,
		Layers = { "Body", "Rise", "Orbit", "Signature", "Pulse" },
		-- V2.1: Mítico "claramente perceptível" na Base (inspeção no Studio)
		Orbiters = 3,
		Rate = 1.4,
		SignatureCount = 4,
		PulseEvery = 3.2,
		Highlight = true,
		Glow = 0.6,
	},
	Divine = {
		Silhouette = 2.0,
		Layers = { "Body", "Depth", "Rise", "Orbit", "Ribbon", "Ground", "Shockwave", "Signature" },
		Orbiters = 3,
		Rate = 1.65,
		SignatureCount = 4,
		PulseEvery = 3.2,
		Highlight = true,
		Glow = 0.8,
	},
	Secret = {
		Silhouette = 2.5,
		Layers = { "Body", "Contrast", "Depth", "Rise", "Outer", "Orbit", "Ribbon", "Ground", "Shockwave", "Signature", "Crown" },
		Orbiters = 4,
		Rate = 1.85,
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
--[[
	Light: MESMA identidade do Full (todas as camadas, órbitas e assinaturas) com 55% da emissão.
	V2.1 (inspeção no Studio: o Light "quase desligado" sumia na Base): ~2× a PRESENÇA sem dobrar
	partículas — elementos maiores e mais sólidos em TODA aura (AuraConfig.Presence), órbitas e
	assinaturas completas também no Light, e o LOD por distância progressivo (AuraController) em
	vez de cortar pela metade aos 55 studs.
]]
AuraConfig.LightScale = { Rate = 0.6, Orbits = 1, Signature = 1, Pulse = true, Ground = true }

-- Presença (V2.1): formas que aparecem no mapa claro/saturado em vez de muitas partículas pequenas
--     Size  multiplica tamanho das partículas, larguras de beams e rastros
--     Fade  multiplica a transparência (exceto o fim da vida): 0,7 = 30% mais opaco
--     MinPeak  nenhuma partícula de aura tem pico menor que isso (studs): faíscas de 0,5 stud
--              somem contra o mapa claro
AuraConfig.Presence = { Size = 1.35, Fade = 0.7, MinPeak = 0.9 }

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

--[[
	MOVIMENTO por estilo (AuraMotion, loop central do AuraController): as formas grandes (fitas,
	rajadas, raios) e as órbitas ganham personalidade. Unidades: rad, rad/s, fração do raio, studs.
	    Speed/Arc      balanço parcial em volta do corpo      Spin        giro contínuo (rad/s)
	    Breath(Speed)  raio respirando                         Bob/Rise    sobe-desce / chama subindo
	    Curve(Speed)   curvatura viva                          Jitter(Rate) saltos bruscos (Electric)
	    Step           degraus por volta (Ice)                 Asym        cada fita no seu ritmo
	    Pulse(Speed)   largura pulsando                        Tip         a ponta de cima anda mais
]]
local function motion(o: { [string]: number }): { [string]: number }
	local base = { Speed = 1.2, Arc = 0.45, Spin = 0, Breath = 0.12, BreathSpeed = 1.1, Bob = 0.35, Rise = 0, Curve = 2.2, CurveSpeed = 1.3, Jitter = 0, JitterRate = 0, Step = 0, Asym = 0.2, Pulse = 0.1, PulseSpeed = 2, Tip = 0.6 }
	for k, v in o do
		base[k] = v
	end
	return base
end
AuraConfig.Motion = {
	-- rápido, nervoso, saltos bruscos e arcos instáveis
	Electric = motion({ Speed = 4.2, Arc = 0.35, Curve = 3.2, CurveSpeed = 6, Jitter = 0.45, JitterRate = 7, Pulse = 0.3, PulseSpeed = 11, Tip = 0.9 }),
	-- sobe e balança, pulsação irregular
	Flame = motion({ Speed = 2.4, Arc = 0.3, Bob = 0.25, Rise = 1.6, Curve = 2.6, CurveSpeed = 3.1, Asym = 0.45, Pulse = 0.2, PulseSpeed = 3.7, Tip = 1.1 }),
	-- lento, caudas flutuando, órbitas assimétricas, distorções pequenas
	Void = motion({ Speed = 0.55, Arc = 0.7, Breath = 0.22, BreathSpeed = 0.6, Bob = 0.5, Curve = 3.4, CurveSpeed = 0.7, Asym = 0.6, Pulse = 0.08, Tip = 1.4 }),
	Dark = motion({ Speed = 0.65, Arc = 0.6, Breath = 0.18, BreathSpeed = 0.7, Bob = 0.45, Rise = 0.4, Curve = 3, CurveSpeed = 0.8, Asym = 0.55, Pulse = 0.08, Tip = 1.2 }),
	-- elegante: órbita contínua + expansão/contração suave
	Celestial = motion({ Speed = 0.9, Arc = 0.25, Spin = 0.55, Breath = 0.2, BreathSpeed = 0.9, Bob = 0.3, Curve = 1.8, CurveSpeed = 1, Asym = 0.1, Pulse = 0.12, PulseSpeed = 1.6, Tip = 0.5 }),
	-- corrente de ar: giro rápido e curvas alongadas
	Wind = motion({ Speed = 2, Arc = 0.3, Spin = 1.9, Breath = 0.1, BreathSpeed = 1.8, Bob = 0.25, Curve = 4.5, CurveSpeed = 2.6, Asym = 0.15, Pulse = 0.1, Tip = 0.8 }),
	-- rígido/preciso: degraus, pulsos frios, pouca curva
	Ice = motion({ Speed = 0.8, Arc = 0.15, Spin = 0.5, Breath = 0.06, Bob = 0.12, Curve = 0.8, CurveSpeed = 0.9, Step = 6, Asym = 0, Pulse = 0.28, PulseSpeed = 2.4, Tip = 0.2 }),
	-- pulsando: expande/contrai em ondas + órbita
	Energy = motion({ Speed = 1.6, Arc = 0.25, Spin = 0.8, Breath = 0.3, BreathSpeed = 3, Bob = 0.25, Curve = 2.4, CurveSpeed = 2.2, Pulse = 0.35, PulseSpeed = 3, Tip = 0.6 }),
	-- fantasma: caudas suaves, fluxo irregular
	Spirit = motion({ Speed = 0.8, Arc = 0.6, Breath = 0.16, BreathSpeed = 0.75, Bob = 0.55, Rise = 0.5, Curve = 3.6, CurveSpeed = 0.9, Asym = 0.7, Pulse = 0.12, Tip = 1.5 }),
	-- pesado: órbita lenta, compressão/expansão forte (atração/repulsão)
	Gravity = motion({ Speed = 0.7, Arc = 0.35, Spin = 0.45, Breath = 0.35, BreathSpeed = 1.2, Bob = 0.2, Curve = 2.6, CurveSpeed = 1.1, Asym = 0.3, Pulse = 0.15, PulseSpeed = 1.2, Tip = 0.7 }),
}
AuraConfig.DefaultMotion = AuraConfig.Motion.Energy

--[[
	FULL = "a mesma aura LIBERADA" (reveal/hero/galeria): além da emissão cheia, mais amplitude de
	movimento, uma fita a mais, órbitas mais rápidas e pulsos mais frequentes. O Light (Base/Torre)
	mantém identidade, cor, assinatura, movimento e silhueta — só com menos camadas extras.
]]
AuraConfig.FullScale = { Amplitude = 1.45, ExtraRibbons = 1, OrbitSpeed = 1.25, PulseEvery = 0.75 }

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
	-- referência de "meia distância" (relatórios/testes); a queda real é progressiva (DistanceRates)
	MidDistance = 55,
	-- taxa por distância da câmera (studs): perto cheio, cai aos poucos, some só depois do Cull.
	-- O PERSONAGEM nunca é afetado: só a aura.
	DistanceRates = { { 30, 1 }, { 60, 0.85 }, { 90, 0.7 }, { 110, 0.55 } },
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
