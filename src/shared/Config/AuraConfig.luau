--!strict
--[[
	AURAS DE ALTA RARIDADE — arquitetura central.
	    RARIDADE = intensidade/complexidade (quantas camadas, densidade, órbitas, raios, pulsos)
	    ESTILO   = comportamento visual (Electric, Flame, Void, Dark, Celestial, Wind, Ice, Energy,
	               Spirit, Gravity): paleta, textura, direção, forma do movimento
	Mythic+Electric e Mythic+Flame têm o MESMO "orçamento" de espetáculo, com comportamento diferente.

	Componentes (montados pelo AuraBuilder, animados pelo AuraController do cliente):
	    Body    partículas no VOLUME do corpo, saindo para fora (escapa da silhueta)
	    Rise    streaks alongados subindo (VelocityParallel)
	    Sparks  faíscas rápidas
	    Orbit   N pontos orbitando com Trail (o cliente gira; 1 loop central)
	    Bolt    arcos elétricos (Beam) entre ombros/mãos/peito/quadril (o cliente pisca/recurva)
	    Pulse   explosão periódica de partículas (o cliente chama Emit)
	    Ground  anel no chão
	Glow (PointLight) é só complemento pequeno — nunca o efeito principal.
	Texturas: só as nativas do Roblox (rbxasset://), nenhuma dependência de pack externo.
]]

local AuraConfig = {}

AuraConfig.Textures = {
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Ember = "rbxasset://textures/particles/fire_sparks_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
}

export type Tier = {
	Layers: number, -- camadas de partículas no corpo (densidade)
	BodyRate: number, -- partículas/s por camada do corpo
	Rise: boolean,
	RiseRate: number,
	Sparks: number, -- taxa de faíscas
	Orbits: number,
	Bolts: number, -- arcos elétricos (só estilos com raios; outros usam como "Wisps")
	PulseEvery: number?, -- segundos entre pulsos (nil = sem)
	PulseCount: number,
	Ground: boolean,
	Glow: number, -- brilho do PointLight complementar
}

-- Escala de espetáculo por raridade (o mesmo para TODOS os estilos)
AuraConfig.Tiers = {
	Legendary = { Layers = 1, BodyRate = 18, Rise = true, RiseRate = 6, Sparks = 0, Orbits = 0, Bolts = 1, PulseEvery = nil, PulseCount = 0, Ground = false, Glow = 0.4 },
	Mythic = { Layers = 2, BodyRate = 22, Rise = true, RiseRate = 10, Sparks = 10, Orbits = 2, Bolts = 2, PulseEvery = nil, PulseCount = 0, Ground = false, Glow = 0.6 },
	Divine = { Layers = 2, BodyRate = 28, Rise = true, RiseRate = 14, Sparks = 16, Orbits = 3, Bolts = 3, PulseEvery = 3.5, PulseCount = 24, Ground = true, Glow = 0.8 },
	Secret = { Layers = 3, BodyRate = 30, Rise = true, RiseRate = 18, Sparks = 22, Orbits = 4, Bolts = 4, PulseEvery = 2.5, PulseCount = 36, Ground = true, Glow = 1 },
} :: { [string]: Tier }

-- Modo Light (base/torres): mantém leitura com menos partículas; Full (reveal/hero): tudo
AuraConfig.LightScale = { Rate = 0.5, Orbits = 0.5, Bolts = 0.5, Sparks = 0.5, Pulse = true, Ground = true }

export type Style = {
	Colors: { { number } }, -- 2–3 cores (principal, secundária, destaque)
	Texture: string, -- chave de AuraConfig.Textures do corpo
	Direction: string, -- "Up" | "Out" | "In" | "Swirl"
	Speed: number, -- velocidade base das partículas
	Lifetime: number,
	Size: number,
	Streak: boolean, -- partículas alongadas na direção do movimento
	Bolts: string, -- "Lightning" (arcos) | "Wisps" (fitas suaves) | "None"
	OrbitSpeed: number, -- rad/s
	Drag: number,
}

AuraConfig.Styles = {
	Electric = { Colors = { { 120, 200, 255 }, { 230, 245, 255 }, { 70, 120, 255 } }, Texture = "Spark", Direction = "Out", Speed = 6, Lifetime = 0.35, Size = 0.5, Streak = true, Bolts = "Lightning", OrbitSpeed = 6, Drag = 2 },
	Flame = { Colors = { { 255, 120, 30 }, { 255, 220, 80 }, { 255, 60, 20 } }, Texture = "Fire", Direction = "Up", Speed = 5, Lifetime = 0.8, Size = 1.4, Streak = false, Bolts = "Wisps", OrbitSpeed = 3, Drag = 1 },
	Void = { Colors = { { 120, 40, 220 }, { 20, 0, 40 }, { 200, 120, 255 } }, Texture = "Smoke", Direction = "In", Speed = 3, Lifetime = 1.1, Size = 1.6, Streak = false, Bolts = "Wisps", OrbitSpeed = 2, Drag = 0.5 },
	Dark = { Colors = { { 40, 30, 50 }, { 150, 30, 60 }, { 10, 10, 15 } }, Texture = "Smoke", Direction = "Up", Speed = 3.5, Lifetime = 1, Size = 1.5, Streak = false, Bolts = "Wisps", OrbitSpeed = 2.5, Drag = 0.6 },
	Celestial = { Colors = { { 255, 240, 170 }, { 255, 255, 255 }, { 150, 220, 255 } }, Texture = "Spark", Direction = "Up", Speed = 4, Lifetime = 1.2, Size = 0.8, Streak = true, Bolts = "Wisps", OrbitSpeed = 2, Drag = 0.8 },
	Wind = { Colors = { { 170, 255, 210 }, { 255, 255, 255 }, { 90, 220, 170 } }, Texture = "Smoke", Direction = "Swirl", Speed = 7, Lifetime = 0.6, Size = 0.9, Streak = true, Bolts = "Wisps", OrbitSpeed = 7, Drag = 1.5 },
	Ice = { Colors = { { 170, 230, 255 }, { 255, 255, 255 }, { 90, 170, 255 } }, Texture = "Spark", Direction = "Out", Speed = 3, Lifetime = 0.9, Size = 0.7, Streak = false, Bolts = "Lightning", OrbitSpeed = 2.5, Drag = 1 },
	Energy = { Colors = { { 255, 90, 200 }, { 255, 230, 255 }, { 140, 80, 255 } }, Texture = "Spark", Direction = "Out", Speed = 5, Lifetime = 0.6, Size = 0.8, Streak = true, Bolts = "Lightning", OrbitSpeed = 4, Drag = 1.2 },
	Spirit = { Colors = { { 130, 255, 230 }, { 220, 255, 250 }, { 60, 200, 255 } }, Texture = "Smoke", Direction = "Up", Speed = 2.5, Lifetime = 1.4, Size = 1.2, Streak = false, Bolts = "Wisps", OrbitSpeed = 1.6, Drag = 0.4 },
	Gravity = { Colors = { { 150, 90, 255 }, { 255, 200, 90 }, { 60, 30, 120 } }, Texture = "Ember", Direction = "In", Speed = 4, Lifetime = 0.9, Size = 0.9, Streak = true, Bolts = "Lightning", OrbitSpeed = 3.5, Drag = 0.7 },
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

-- ORÇAMENTO de performance (cliente: AuraController)
AuraConfig.Budget = {
	-- além disso o cliente desliga as partículas da aura (studs da câmera)
	CullDistance = 120,
	-- auras com animação (órbita/raio/pulso) ao mesmo tempo: as mais próximas da câmera
	MaxAnimated = 10,
	-- auras FULL simultâneas (reveal/hero/galeria); as outras ficam Light
	MaxFull = 3,
	-- loop central do cliente (Hz)
	UpdateRate = 30,
	-- mobile / qualidade baixa: fator nas taxas de emissão
	LowEndRateScale = 0.5,
	-- teto de partículas/s somadas de UMA aura (Full) — o teste garante
	MaxRatePerAura = 220,
}

return AuraConfig
