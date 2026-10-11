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
		Divine = {
			Duration = 3.4, Intro = "rarity.Divine", SkyEffect = "Heaven", Darken = 0.55,
			FallStart = 1.0, Impact = 1.6, Rise = 2.0, Pose = 2.3, Continue = 2.9,
			FovFall = 82, Shake = 0.85, RingSize = 26, Debris = 20, Trail = "Light", Lighting = { 255, 245, 190 },
			Sounds = { "RareTrigger", "FallingWhoosh", "ImpactBass", "ImpactDebris", "DivineStinger" },
		},
		Secret = {
			Duration = 4.2, Intro = "reveal.secret_intro", SkyEffect = "Rift", Darken = 0.92,
			Silence = 0.35, FallStart = 1.35, Impact = 1.75, Rise = 2.4, Pose = 2.8, Continue = 3.6,
			FovFall = 84, Shake = 1.0, RingSize = 34, Debris = 26, Trail = "Rift", Lighting = { 255, 120, 40 },
			WhiteOut = 0.12,
			Sounds = { "RiftHum", "FallingWhoosh", "ImpactBass", "ImpactDebris", "SecretStinger" },
		},
	},

	-- Com OCULTAR ligado, o Secreto ainda toca a cinemática completa (é raro o bastante)
	ForceCinematicForSecret = true,
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
}
