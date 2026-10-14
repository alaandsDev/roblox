--!strict
--[[
	Apresentação do resultado do roll (só visual, no cliente). Toda decisão "que tipo de
	reveal tocar" sai daqui via Modules/RevealPlanner — nada de `if rarity == "Legendary"`
	espalhado pelos scripts.

	Mode:
	  Normal      -> dado gira, flash, personagem, nome (≈1.2–1.8 s)
	  Enhanced    -> Normal com mais brilho/partículas
	  HeroLanding -> cinemática: silhueta no céu, queda, impacto, pose (Cinematic = preset abaixo)
	CompactStyle (quando OCULTAR está ligado): Plain | Glow | Special | Highlight | Premium
	AutoRoll:     None (continua) | Pause (pausa durante o reveal)
	Social:       None | Discreet (msg pequena no servidor) | Global | Highlight
]]

return {
	ByRarity = {
		Common = { Mode = "Normal", Duration = 1.2, CompactStyle = "Plain", AutoRoll = "None", Social = "None", Flash = 0.2 },
		Uncommon = { Mode = "Normal", Duration = 1.3, CompactStyle = "Plain", AutoRoll = "None", Social = "None", Flash = 0.3 },
		Rare = { Mode = "Normal", Duration = 1.5, CompactStyle = "Glow", AutoRoll = "None", Social = "None", Flash = 0.45, SmallEffect = true },
		Epic = { Mode = "Enhanced", Duration = 1.8, CompactStyle = "Glow", AutoRoll = "None", Social = "None", Flash = 0.6, SmallEffect = true },
		Legendary = { Mode = "HeroLanding", Cinematic = "Legendary", CompactStyle = "Special", AutoRoll = "Pause", Social = "None" },
		Mythic = { Mode = "HeroLanding", Cinematic = "Mythic", CompactStyle = "Highlight", AutoRoll = "Pause", Social = "Discreet" },
		Divine = { Mode = "HeroLanding", Cinematic = "Divine", CompactStyle = "Premium", AutoRoll = "Pause", Social = "Global" },
		Secret = { Mode = "HeroLanding", Cinematic = "Secret", CompactStyle = "Premium", AutoRoll = "Pause", Social = "Highlight" },
	},

	-- Presets da cinemática (tempos em segundos a partir do fim do roll)
	Cinematics = {
		Legendary = {
			Duration = 2.6, Intro = nil, SkyEffect = "None", Darken = 0.35,
			FallStart = 0.4, Impact = 1.05, Rise = 1.45, Pose = 1.7, Continue = 2.3,
			FovFall = 78, Shake = 0.35, RingSize = 14, Debris = 10, Trail = "Wind", Lighting = nil,
			Sounds = { "RareTrigger", "FallingWhoosh", "ImpactBass", "ImpactDebris", "RevealStinger" },
		},
		Mythic = {
			Duration = 3.0, Intro = "rarity.Mythic", SkyEffect = "Aura", Darken = 0.5,
			FallStart = 0.75, Impact = 1.35, Rise = 1.75, Pose = 2.0, Continue = 2.6,
			FovFall = 80, Shake = 0.6, RingSize = 20, Debris = 16, Trail = "Energy", Lighting = { 255, 70, 110 },
			Sounds = { "RareTrigger", "FallingWhoosh", "ImpactBass", "ImpactDebris", "MythicStinger" },
		},
		--[[
			DIVINE / SECRET = JACKPOT REVEAL (Effects/JackpotReveal): palco NO MUNDO (local do
			cliente, longe do mapa) com a câmera REAL — o ViewportFrame antigo não renderiza
			partículas, Beams nem Highlight, então a Aura Full nunca aparecia na cinemática.
			    ALTO -> QUEDA -> IMPACTO -> HERO LANDING -> Aura Full -> nome + raridade
			Tempos em segundos desde o início. Stage = "World" manda para o JackpotReveal.
		]]
		Divine = {
			Stage = "World", Duration = 4.8, Intro = "rarity.Divine", SkyEffect = "Heaven", Darken = 0.25,
			-- personagem surge alto (DropHeight × altura do personagem, mín. 45 studs) e cai rápido
			Appear = 0.3, FallStart = 0.75, Impact = 1.5, Rise = 1.95, Pose = 2.4, Title = 2.05, Continue = 3.7,
			DropHeight = 9, MinDrop = 45, FallPower = 3, Camera = "Track",
			FovFall = 74, Shake = 0.85, ShakeTime = 0.45, RingSize = 24, Debris = 18, Sparks = 36,
			Flash = 0.4, Tint = { 255, 236, 190 }, TintStrength = 0.12, Trail = "Light", Lighting = { 255, 245, 190 },
			AuraEntry = "Burst", -- Aura Divine Full inteira no impacto
			Sounds = { "RareTrigger", "FallingWhoosh", "ImpactBass", "ImpactDebris", "DivineStinger" },
		},
		Secret = {
			Stage = "World", Duration = 6.4, Intro = "reveal.secret_intro", SkyEffect = "Rift", Darken = 0.6,
			-- suspense (tela escurece, falhas, fenda abre) -> surge MUITO alto, carrega energia,
			-- cai devagar e ACELERA (FallPower alto) -> câmera mergulha junto -> CORTE para o chão
			-- -> câmera lenta nos últimos instantes -> impacto forte -> aura entra em camadas
			Silence = 0.35, Suspense = 1.3, Appear = 1.0, FallStart = 2.0, Impact = 3.05,
			SlowMo = 0.22, SlowMoScale = 0.35, Rise = 3.7, Pose = 4.3, Title = 3.9, Continue = 5.3,
			DropHeight = 18, MinDrop = 90, FallPower = 4.5, Camera = "DiveCut",
			FovFall = 84, Shake = 1.0, ShakeTime = 0.8, RingSize = 40, Debris = 30, Sparks = 80,
			Flash = 0.9, WhiteOut = 0.12, Tint = { 120, 60, 200 }, TintStrength = 0.35, Trail = "Rift", Lighting = { 255, 120, 40 },
			AuraEntry = "Layers", LayerStep = 0.16, -- Aura Secret Full entra por zonas (corpo -> fora -> coroa)
			Sounds = { "RiftHum", "FallingWhoosh", "ImpactBass", "ImpactDebris", "SecretStinger" },
		},
	},

	-- Com OCULTAR ligado, Divino e Secreto ainda tocam a cinemática completa: são eventos
	-- excepcionais (OCULTAR é para não poluir a tela com os rolls comuns)
	ForceCinematicForSecret = true,
	ForceCinematicForDivine = true,
	-- Pular: liberado depois de ver a cinemática da raridade X vezes. A PRIMEIRA descoberta de
	-- Mítico/Divino/Secreto sempre é completa (MinTierNoSkipOnFirst).
	SkipAfterViews = 3,
	MinTierNoSkipOnFirst = 6,
	-- Fecha sozinho X s depois do botão CONTINUAR aparecer (0 = só no clique). Em AUTO fecha sempre.
	AutoCloseDelay = 0,
	AutoCloseDelayAuto = 1.2,

	-- Qualidade (ReducedEffects -> Low; celular -> Medium)
	Quality = {
		High = { Debris = 1, Particles = 1, Trails = true, SpeedLines = 14, Cracks = true },
		Medium = { Debris = 0.6, Particles = 0.6, Trails = true, SpeedLines = 8, Cracks = true },
		Low = { Debris = 0.25, Particles = 0.3, Trails = false, SpeedLines = 4, Cracks = false },
	},

	-- Mensagens sociais: intervalo mínimo entre anúncios do mesmo jogador
	SocialCooldown = 20,

	-- Campo de visão base do palco do reveal
	BaseFov = 70,

	-- Palco do Jackpot Reveal (mundo, local): bem acima do mapa, nunca encosta em nada do jogo
	JackpotStage = { Position = { 0, 1600, 0 }, GroundRadius = 46, CameraFov = 62, MobileShakeScale = 0.6 },
}
