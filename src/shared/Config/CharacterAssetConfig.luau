--!strict
--[[
	Pipeline de personagens do Roll Legends (modelos visuais vindos de um pack de origem).

	SOURCE MODEL (Workspace.Anime Pack / third_party/AnimePack.rbxm, só no desenvolvimento)
	  -> SANITIZAÇÃO   (CharacterAssetPipeline.sanitize: clona e remove tudo que não é visual)
	  -> VALIDAÇÃO     (CharacterAssetPipeline.validate)
	  -> CHARACTER ASSET (assets/Characters.rbxm -> ReplicatedStorage.CharacterAssets.<CharacterId>)
	  -> CharacterModelFactory.build / spawn (Base, Reveal, Inventário, Índice, Torres, Hero Landing)

	O jogo NUNCA lê o pack em runtime: só ReplicatedStorage.CharacterAssets. Sem o asset (ou
	asset inválido), o factory usa o placeholder em blocos e avisa no Output (desenvolvimento).

	Chaves:
	  CharacterId     chave estável (save, config, referências). Nunca muda.
	  DisplayName     nome exibido (pode mudar sem migração).
	  SourceModelName nome do modelo no pack (só desenvolvimento/pipeline).

	CATÁLOGO DE LANÇAMENTO: 121 personagens (10 pilotos curados + 111 gerados por
	tools/characters/gen_launch_catalog.py; metadados em CharacterConfig.Launch).
	Os 112 F2P são o roster do roll (por Dice: DiceCore) e da coleção do Índice; os 9 Premium
	ficam fora dos Dice (progresso próprio no Índice).
]]

export type VFXSpec = {
	-- Nomes de efeitos PRÓPRIOS do personagem aceitos (o resto é removido)
	Light: { string }?, -- base/torres: poucos e leves
	Full: { string }?, -- reveal/hero landing
}

export type AssetSpec = {
	SourceModelName: string, -- nome no pack (só desenvolvimento)
	SourcePath: string, -- caminho dentro do pack (sem "Anime Pack.")
	PilotReason: string?,
	VFX: VFXSpec?,
	VFXExcluded: { string }?, -- VFX próprios deixados de fora (golpes/rastros): personagem vai para VFX REVIEW
	CatalogStatus: string?, -- status técnico do catálogo quando não é APPROVED (ex.: NEEDS_OPTIMIZATION)
	-- Ajustes visuais CENTRALIZADOS (nunca espalhados pelo código). nil = padrão.
	VisualScale: number?, -- multiplicador da altura normalizada (limitado por VisualScaleLimits)
	VisualOffset: { number }?, -- {x, y, z}: deslocamento em relação ao pivô (studs normalizados)
}

local CharacterAssetConfig = {}

-- Onde ficam os assets sanitizados (vem de assets/Characters.rbxm no build)
CharacterAssetConfig.StorageName = "CharacterAssets"
-- Nome do pack de origem (só ferramentas de desenvolvimento)
CharacterAssetConfig.SourcePackName = "Anime Pack"
CharacterAssetConfig.AssetVersion = 1

--[[
	NORMALIZAÇÃO (regra única para todos):
	  1. Altura do CORPO = dos pés (fundo das pernas) ao topo da peça Head. Cabelo, chapéu,
	     armas e capas NÃO entram na medida (preserva a silhueta: cabelo grande continua grande).
	  2. O pipeline escala o modelo para BodyHeight = 5 studs (corpo R6 padrão) e coloca o pivô
	     no centro dos pés, olhando para -Z.
	  3. Em jogo, o factory escala igual ao placeholder: 1,25 x ModelScale da raridade
	     (x VisualScale do personagem, se houver). Corpo final ~6,25 (Comum) a ~8,5 (Secreto).
	  4. Limites: se a caixa total (com armas/cabelo) passar de MaxBounds, o personagem é
	     marcado como AVISO no relatório (não é cortado nem reduzido automaticamente).
]]
CharacterAssetConfig.BodyHeight = 5
CharacterAssetConfig.RuntimeScale = 1.25
CharacterAssetConfig.VisualScaleLimits = { Min = 0.85, Max = 1.2 }
CharacterAssetConfig.MaxBounds = { X = 10, Y = 9, Z = 10 } -- em unidades normalizadas (corpo = 5)
CharacterAssetConfig.FeetTolerance = 0.05
-- Meta preferencial de peças por personagem (acima disso: justificar no relatório)
CharacterAssetConfig.PreferredMaxParts = 40
-- Orçamento do asset final: acima disso o personagem é NEEDS_OPTIMIZATION no relatório
-- (nada é cortado automaticamente: cabelo, capa, arma e roupa nunca saem para bater número)
CharacterAssetConfig.Budget = { MaxParts = 40, MaxInstances = 300 }

--[[
	Correção de ROUPA por id de template (genérica: vale para todo personagem que usar o mesmo id).
	Alguns modelos do pack apontam o ShirtTemplate/PantsTemplate para o ITEM da loja (Shirt/Pants)
	em vez da IMAGEM do template — o Roblox não desenha nada e o personagem aparece sem roupa.
	O comando DEV ClothingCheck (Studio, Play, servidor) descobre a imagem certa e imprime as
	linhas prontas para colar aqui. Chave = id do pack (string); valor = template final.
]]
CharacterAssetConfig.ClothingTemplateOverrides = {} :: { [string]: string }

--[[
	AUDITORIA DE ROUPA (por AssetId único; sem rede no runtime nem no build).
	O status vem daqui — evidência coletada no Studio com o comando DEV ClothingCheck — e o
	pipeline só LÊ. Status no relatório (CLOTHING_AUDIT.md):
	  OK               verificado e carregando;
	  UNCHECKED        ainda não verificado (padrão para todo id que não está aqui);
	  REVIEW_REQUIRED  asset externo com problema: o personagem é GERADO mesmo assim (AVISO),
	                   mas aparece na revisão até ganhar override aprovado;
	  OVERRIDDEN       existe ClothingTemplateOverrides[id] aprovado (vale sobre qualquer status).
	Asset externo indisponível NÃO é erro de sanitização: perda visual no sanitizer continua FALHA.
]]
export type ClothingAudit = { Status: string, Kind: string?, Note: string? }
CharacterAssetConfig.ClothingStatus = {
	-- ClothingCheck no Studio (2026-10): AssetType Image, GetProductInfo ok, PreloadAsync sem resposta.
	-- Substituição aprovada, mas ainda sem roupa original publicada: fica para revisão.
	["2065247269"] = { Status = "REVIEW_REQUIRED", Kind = "Shirt", Note = "Image \"Killua Zoldylock (T)\"; não carrega (PreloadAsync sem resposta)" },
	["2065252088"] = { Status = "REVIEW_REQUIRED", Kind = "Pants", Note = "Image \"Killua Zoldylock (B)\"; não carrega (PreloadAsync sem resposta)" },
} :: { [string]: ClothingAudit }

-- Status efetivo de um id de roupa (override aprovado > status registrado > UNCHECKED)
function CharacterAssetConfig.clothingStatus(assetId: string): string
	if CharacterAssetConfig.ClothingTemplateOverrides[assetId] then
		return "OVERRIDDEN"
	end
	local entry = CharacterAssetConfig.ClothingStatus[assetId]
	return if entry then entry.Status else "UNCHECKED"
end

-- Classes PROIBIDAS em qualquer asset final (o validate falha se aparecer qualquer uma)
CharacterAssetConfig.ForbiddenClasses = {
	"Script",
	"LocalScript",
	"ModuleScript",
	"RemoteEvent",
	"RemoteFunction",
	"UnreliableRemoteEvent",
	"BindableEvent",
	"BindableFunction",
	"Sound",
	"SoundGroup",
	"Animation",
	"Animator",
	"AnimationController",
	"KeyframeSequence",
	"Tool",
	"BillboardGui",
	"SurfaceGui",
	"ScreenGui",
	"ProximityPrompt",
	"ClickDetector",
	"BodyMover",
	"Constraint",
	"ValueBase",
	"Configuration",
	"ForceField",
	"Explosion",
}

-- Classes que podem FICAR no asset (tudo que não está aqui é removido na sanitização)
CharacterAssetConfig.AllowedClasses = {
	"Model",
	"Folder",
	"Part",
	"MeshPart",
	"WedgePart",
	"CornerWedgePart",
	"TrussPart",
	"UnionOperation",
	"SpecialMesh",
	"BlockMesh",
	"CylinderMesh",
	"Decal",
	"Texture",
	"SurfaceAppearance",
	"Shirt",
	"Pants",
	"ShirtGraphic",
	"BodyColors",
	"Attachment",
	"Humanoid", -- só se houver roupa (Shirt/Pants só aparecem com Humanoid); fica inerte
	-- VFX: só os que passam pela whitelist do personagem
	"ParticleEmitter",
	"Beam",
	"Trail",
	"Fire",
	"Smoke",
	"Sparkles",
	"PointLight",
	"SpotLight",
}

-- Classes de efeito (só ficam se o NOME estiver na whitelist do personagem)
CharacterAssetConfig.VFXClasses = { "ParticleEmitter", "Beam", "Trail", "Fire", "Smoke", "Sparkles", "PointLight", "SpotLight" }

-- Efeitos GENÉRICOS do jogo de origem (ataques, movimento, sistema de nível): nunca entram
CharacterAssetConfig.GenericVFXNames = {
	"MoveT",
	"Break",
	"Bubbles",
	"Slider",
	"Smoke",
	"Hit1",
	"Hit2",
	"Block",
	"SoruP",
	"LevelParticle",
	"SenzuEat",
}

-- Limites de VFX por personagem (performance: 400 personagens no pior caso)
CharacterAssetConfig.VFXLimits = {
	MaxLight = 2, -- efeitos ativos no modo Light (base)
	MaxFull = 6, -- efeitos guardados no asset (modo Full)
	MaxRate = 12, -- partículas/s por emissor (o pack usa valores bem maiores)
	MaxLights = 1, -- PointLight/SpotLight
}

-- Peças do corpo R6 (obrigatórias) e o "osso" (grupo que se move junto) de cada uma
CharacterAssetConfig.R6Parts = {
	Head = "Head",
	Torso = "Torso",
	["Left Arm"] = "LeftArm",
	["Right Arm"] = "RightArm",
	["Left Leg"] = "LeftLeg",
	["Right Leg"] = "RightLeg",
} :: { [string]: string }

-- Modos de VFX por contexto (o mobile/qualidade baixa pode reduzir: ver LodController)
CharacterAssetConfig.VFXModes = {
	Base = "Light",
	Reveal = "Full",
	Inventory = "None",
	Index = "None",
	Tower = "Light",
	HeroLanding = "Full",
	Gallery = "Full",
}

-- Especificação de asset de cada personagem do pipeline (chave = CharacterId).
-- Metadados de jogo (nome, raridade, família, stats) ficam em CharacterConfig.Pilots / Launch.
-- Os 10 pilotos têm specs curadas aqui; os outros 111 vêm do bloco gerado logo abaixo.
CharacterAssetConfig.Assets = {
	char_sacha_base = {
		SourceModelName = "Sasha",
		SourcePath = "AOT.Sasha",
		PilotReason = "Personagem SIMPLES: 8 peças, sem scripts e sem VFX (referência do caminho mínimo).",
	},
	char_ichiro_base = {
		SourceModelName = "Ichigo",
		SourcePath = "Bleach Pack.Ichigo",
		PilotReason = "ESPADA soldada ao rig + forma base de uma TRANSFORMAÇÃO.",
	},
	char_ichiro_hollow = {
		SourceModelName = "Hollow Ichigo",
		SourcePath = "Bleach Pack.Hollow Ichigo.Hollow Ichigo",
		PilotReason = "TRANSFORMAÇÃO (FormTier 2 da família ichiro), Mítico, máscara + espada, caminho aninhado no pack.",
	},
	char_goko_base = {
		SourceModelName = "Goku",
		SourcePath = "DBZ.Goku",
		PilotReason = "CABELO como Accessory (GokuHair, um dos 2 Accessory do pack): testa Handle/solda/atalho de acessório.",
	},
	char_barbalva_base = {
		SourceModelName = "Whitebeard",
		SourcePath = "One Piece Pack.Whitebeard",
		PilotReason = "ROUPA/CASACO complexo (5 MeshParts, bigode, casaco), corpo grande: testa normalização.",
	},
	char_killuo_base = {
		SourceModelName = "Killua",
		SourcePath = "HXH.Killua",
		PilotReason = "Forma base da transformação com VFX (mesma roupa do Killuo Relâmpago).",
	},
	char_killuo_godspeed = {
		SourceModelName = "Killua Godspeed",
		SourcePath = "HXH.Killua Godspeed",
		PilotReason = "VFX PRÓPRIO aceitável (raios Lightning/Reiatsu), Lendário, transformação (FormTier 2).",
		VFX = { Light = { "Lightning" }, Full = { "Lightning", "Reiatsu" } },
	},
	char_zabuzo_base = {
		SourceModelName = "Zabuza",
		SourcePath = "NARUTO.Zabuza",
		PilotReason = "ARMA GRANDE nas costas (BackSword): testa escala/caixa total sem a arma invadir a base.",
	},
	char_yamamotu_base = {
		SourceModelName = "Yamamoto",
		SourcePath = "Bleach Pack.Yamamoto",
		PilotReason = "VFX de FOGO com várias classes (ParticleEmitter, Trail, Beam, PointLight): testa a whitelist por classe/nome.",
		VFX = { Light = { "Fire" }, Full = { "Fire", "PointLight" } },
	},
	char_goju_base = {
		SourceModelName = "Gojo Satoru",
		SourcePath = "JJK.Gojo Satoru",
		PilotReason = "Candidato DIVINO (raridade alta, maior escala de raridade), 17 peças com 5 MeshParts.",
	},
} :: { [string]: AssetSpec }

-- BEGIN LAUNCH CATALOG (gerado por tools/characters/gen_launch_catalog.py — não editar à mão)
local launchAssets: { [string]: AssetSpec } = {
	char_anny_school = { SourceModelName = "Annie (Junior High)", SourcePath = "AOT.Annie (Junior High)" },
	char_mikaza_formal = { SourceModelName = "Mikasa (Formal)", SourcePath = "AOT.Mikasa (Formal)" },
	char_sacha_suit = { SourceModelName = "Sasha (Suit)", SourcePath = "AOT.Sasha (Suit)" },
	char_chiko_base = { SourceModelName = "Chika", SourcePath = "OTHER.MISC.Chika" },
	char_erwyn_gala = { SourceModelName = "Erwin (Alt)", SourcePath = "AOT.Erwin (Alt)" },
	char_kurilo_base = { SourceModelName = "Krillin", SourcePath = "DBZ.Krillin" },
	char_saitano_base = { SourceModelName = "Saitama", SourcePath = "OTHER.MISC.Saitama" },
	char_gom_base = { SourceModelName = "Gon", SourcePath = "HXH.Gon" },
	char_sanjo_young = { SourceModelName = "ptsSanji", SourcePath = "One Piece Pack.ptsSanji" },
	char_kazumo_base = { SourceModelName = "Kazuma", SourcePath = "OTHER.Kazuma", VFXExcluded = { "Trail" } },
	char_rinn_base = { SourceModelName = "Rin", SourcePath = "FATE.Rin" },
	char_grei_base = { SourceModelName = "Gray", SourcePath = "Fairy Tail.Gray" },
	char_rukya_base = { SourceModelName = "Rukia", SourcePath = "Bleach Pack.Rukia", VFXExcluded = { "Trail" } },
	char_hizoka_base = { SourceModelName = "Hisoka", SourcePath = "HXH.Hisoka (2ª ocorrência)", VFX = { Light = { "Aura" }, Full = { "Aura" } } },
	char_erem_base = { SourceModelName = "Eren", SourcePath = "AOT.Eren" },
	char_anny_base = { SourceModelName = "Annie", SourcePath = "AOT.Annie" },
	char_mikaza_base = { SourceModelName = "Mikasa", SourcePath = "AOT.Mikasa" },
	char_erem_veteran = { SourceModelName = "Eren Post-time skip", SourcePath = "AOT.Eren Post-time skip" },
	char_erwyn_base = { SourceModelName = "Erwin", SourcePath = "AOT.Erwin" },
	char_anny_titan = { SourceModelName = "Female Titan", SourcePath = "AOT.Female Titan" },
	char_erem_titan = { SourceModelName = "Attack Titan", SourcePath = "AOT.Attack Titan" },
	char_natzu_base = { SourceModelName = "Natsu", SourcePath = "Fairy Tail.Natsu" },
	char_todoruki_base = { SourceModelName = "Todoroki", SourcePath = "My Hero Academia Pack.Todoroki", VFXExcluded = { "ChargeParticle2" } },
	char_ase_base = { SourceModelName = "Ace", SourcePath = "One Piece Pack.Ace" },
	char_bakugu_base = { SourceModelName = "Bakugo", SourcePath = "My Hero Academia Pack.Bakugo" },
	char_akaino_base = { SourceModelName = "Akainu", SourcePath = "One Piece Pack.Akainu" },
	char_narotu_young = { SourceModelName = "ptsNaruto", SourcePath = "NARUTO.ptsNaruto" },
	char_sasuko_young = { SourceModelName = "ptsSasuke", SourcePath = "NARUTO.ptsSasuke" },
	char_nejo_base = { SourceModelName = "Neji", SourcePath = "NARUTO.Neji" },
	char_roqueli_base = { SourceModelName = "Rock Lee", SourcePath = "NARUTO.Rock Lee.Rock Lee" },
	char_gaaro_base = { SourceModelName = "Gaara", SourcePath = "NARUTO.Gaara", VFX = { Light = { "FeetParticle" }, Full = { "FeetParticle", "Particle" } } },
	char_kakaxi_base = { SourceModelName = "Kakashi", SourcePath = "NARUTO.Kakashi" },
	char_narotu_base = { SourceModelName = "tsNaruto", SourcePath = "NARUTO.tsNaruto" },
	char_zoru_young = { SourceModelName = "ptsZoro", SourcePath = "One Piece Pack.ptsZoro", VFXExcluded = { "Trail" } },
	char_ginn_base = { SourceModelName = "Gin", SourcePath = "Bleach Pack.Gin" },
	char_kisuko_base = { SourceModelName = "Kisuke", SourcePath = "Bleach Pack.Kisuke", VFXExcluded = { "NoBlade2", "Trail" } },
	char_trunkz_base = { SourceModelName = "Trunks", SourcePath = "DBZ.Trunks", VFX = { Light = { "SaiyanAura" }, Full = { "SaiyanAura" } } },
	char_tanjiru_base = { SourceModelName = "Tanjiro", SourcePath = "OTHER.MISC.Tanjiro", VFXExcluded = { "FireTrail1", "FireTrail2", "Trail", "WaterTrail1", "WaterTrail2" } },
	char_zoru_base = { SourceModelName = "tsZoro", SourcePath = "One Piece Pack.tsZoro", VFXExcluded = { "Trail" } },
	char_shankz_base = { SourceModelName = "Shanks", SourcePath = "One Piece Pack.Shanks" },
	char_deko_base = { SourceModelName = "Deku", SourcePath = "My Hero Academia Pack.Deku", VFXExcluded = { "ChargeParticle2" } },
	char_yuzuke_base = { SourceModelName = "Yusuke", SourcePath = "YYH.Yusuke" },
	char_lemilio_base = { SourceModelName = "Lemillion", SourcePath = "My Hero Academia Pack.Lemillion" },
	char_lufy_base = { SourceModelName = "tsLuffy", SourcePath = "One Piece Pack.TS Luffy.tsLuffy" },
	char_pikkolo_base = { SourceModelName = "Piccolo", SourcePath = "DBZ.Piccolo" },
	char_olmaito_base = { SourceModelName = "All Might", SourcePath = "My Hero Academia Pack.All Might" },
	char_lanseiro_base = { SourceModelName = "Lancer", SourcePath = "FATE.Lancer ", VFXExcluded = { "ChargeParticle", "ChargeParticle2", "ShootParticle", "Trail", "Trail1", "Trail2" } },
	char_minatu_base = { SourceModelName = "Minato", SourcePath = "NARUTO.Minato.Minato" },
	char_goko_majin_saga = { SourceModelName = "Buu Saga Goku", SourcePath = "DBZ.Buu Saga Goku", VFX = { Light = { "SaiyanAura" }, Full = { "Lightning", "SaiyanAura" } } },
	char_kaulifa_base = { SourceModelName = "Caulifa", SourcePath = "DBZ.Caulifa", VFX = { Light = { "SaiyanAura" }, Full = { "Lightning", "SaiyanAura", "SaiyanAura2" } } },
	char_deko_awakened = { SourceModelName = "Deku Awakened", SourcePath = "My Hero Academia Pack.Deku Awakened", VFXExcluded = { "ChargeParticle2", "ShootParticle" } },
	char_toshiru_base = { SourceModelName = "Toshiro", SourcePath = "Bleach Pack.Toshiro.Toshiro", VFXExcluded = { "Trail" } },
	char_byakuto_base = { SourceModelName = "Byakuya", SourcePath = "Bleach Pack.Byakuya", VFXExcluded = { "NoBlade", "NoBlade2", "Trail" } },
	char_shunzo_base = { SourceModelName = "Shunsui", SourcePath = "Bleach Pack.Shunsui" },
	char_starko_base = { SourceModelName = "Starrk", SourcePath = "Bleach Pack.Starrk", VFXExcluded = { "Trail" } },
	char_hiey_base = { SourceModelName = "Hiei", SourcePath = "YYH.Hiei" },
	char_yoruka_base = { SourceModelName = "Yoruichi", SourcePath = "Bleach Pack.Yoruichi.Yoruichi" },
	char_yuzuke_demon = { SourceModelName = "Yusuke Mode", SourcePath = "YYH.Yusuke Mode", VFX = { Light = { "BigParticle" }, Full = { "BigParticle", "SmallParticle" } } },
	char_kiritsugo_base = { SourceModelName = "Kiritsugu", SourcePath = "FATE.Kiritsugu" },
	char_seiba_base = { SourceModelName = "Saber", SourcePath = "FATE.Fate Pack.Saber", VFXExcluded = { "Charge" } },
	char_shiro_base = { SourceModelName = "Shirou", SourcePath = "FATE.Fate Pack.Shirou" },
	char_akcel_base = { SourceModelName = "Accel", SourcePath = "OTHER.Accel" },
	char_lau_base = { SourceModelName = "ptsLaw", SourcePath = "One Piece Pack.ptsLaw", VFXExcluded = { "Trail" } },
	char_rika_base = { SourceModelName = "Rikka", SourcePath = "OTHER.Rikka", VFX = { Light = { "CircleParticle" }, Full = { "CircleParticle", "FireOutParticle" } }, VFXExcluded = { "ChargeParticle", "ChargeParticle2", "ShootParticle" } },
	char_gilgamex_base = { SourceModelName = "Gilgamesh", SourcePath = "FATE.Fate Pack.Gilgamesh" },
	char_shiro_archer = { SourceModelName = "Archer (EMIYA)", SourcePath = "FATE.Archer (EMIYA)", VFX = { Light = { "PointLight" }, Full = { "PointLight" } }, VFXExcluded = { "SmallShoot" } },
	char_grimjau_base = { SourceModelName = "Grimmjow", SourcePath = "Bleach Pack.Grimmjow" },
	char_shinjo_base = { SourceModelName = "Shinji", SourcePath = "Bleach Pack.Shinji", VFXExcluded = { "Trail" } },
	char_ulkiorra_base = { SourceModelName = "Ulq", SourcePath = "Bleach Pack.Ulquiorra.Ulq", VFXExcluded = { "Trail" } },
	char_itaxi_base = { SourceModelName = "Itachi", SourcePath = "NARUTO.Itachi" },
	char_peinn_base = { SourceModelName = "Pain", SourcePath = "NARUTO.Pain" },
	char_goko_dark_base = { SourceModelName = "Goku Black [NEW]", SourcePath = "DBZ.Goku Black.Goku Black [NEW]" },
	char_ilumi_base = { SourceModelName = "Illumi", SourcePath = "HXH.Illumi" },
	char_vejita_base = { SourceModelName = "Vegeta", SourcePath = "DBZ.Vegeta", CatalogStatus = "NEEDS_OPTIMIZATION" },
	char_ilumi_awakened = { SourceModelName = "Illumi Awakened", SourcePath = "HXH.Illumi Awakened", VFXExcluded = { "Beam" } },
	char_vejita_majin = { SourceModelName = "Majin Vegeta", SourcePath = "DBZ.Majin Vegeta", VFX = { Light = { "SaiyanAura" }, Full = { "SaiyanAura" } } },
	char_ulkiorra_release = { SourceModelName = "R1", SourcePath = "Bleach Pack.Ulquiorra.R1", VFXExcluded = { "Trail" } },
	char_ichiro_vasto = { SourceModelName = "Vasto", SourcePath = "Bleach Pack.Hollow Ichigo.Vasto" },
	char_bakugu_awakened = { SourceModelName = "Awakened Bakugo", SourcePath = "My Hero Academia Pack.Awakened Bakugo", VFX = { Light = { "Sparky" }, Full = { "Sparky" } } },
	char_grei_awakened = { SourceModelName = "Grey Awakening", SourcePath = "Fairy Tail.Grey Awakening", VFX = { Light = { "SaiyanAura" }, Full = { "SaiyanAura", "SaiyanAura2", "dust", "dust2" } } },
	char_rika_awakened = { SourceModelName = "Rikka Awakened", SourcePath = "OTHER.Rikka Awakened", VFX = { Light = { "Blood" }, Full = { "Blood", "CircleParticle", "FireOutParticle" } }, VFXExcluded = { "ChargeParticle", "ChargeParticle2", "ShootParticle" } },
	char_gom_adult = { SourceModelName = "Adult Gon", SourcePath = "HXH.Adult Gon", VFX = { Light = { "SaiyanAura" }, Full = { "SaiyanAura", "SaiyanAura2", "SaiyanAura3" } } },
	char_natzu_awakened = { SourceModelName = "Natsu Awakened", SourcePath = "Fairy Tail.Natsu Awakened", VFX = { Light = { "SaiyanAura" }, Full = { "CircleParticle", "Fire", "Particle", "RyujinLight", "SaiyanAura" } }, VFXExcluded = { "ShootParticle", "SmallShoot" } },
	char_roqueli_gates = { SourceModelName = "ROCK LEE GATES", SourcePath = "NARUTO.Rock Lee.ROCK LEE GATES", VFX = { Light = { "Aura" }, Full = { "Aura", "ParticleEmitter" } } },
	char_gohin_base = { SourceModelName = "Gohan", SourcePath = "DBZ.Gohan" },
	char_mighto_base = { SourceModelName = "Might Guy", SourcePath = "NARUTO.Might Guy.Might Guy" },
	char_brolli_base = { SourceModelName = "Broly", SourcePath = "DBZ.Broly.Broly" },
	char_sasuko_base = { SourceModelName = "tsSasuke", SourcePath = "NARUTO.tsSasuke", VFX = { Light = { "ParticleEmitter" }, Full = { "ParticleEmitter" } }, VFXExcluded = { "ChargeParticle2" } },
	char_lufy_snake = { SourceModelName = "Snakeman", SourcePath = "One Piece Pack.TS Luffy.Snakeman" },
	char_mighto_gate5 = { SourceModelName = "5TH GATE", SourcePath = "NARUTO.Might Guy.5TH GATE", VFX = { Light = { "Aura" }, Full = { "Aura", "ParticleEmitter" } }, VFXExcluded = { "Beam1", "Beam10", "Beam11", "Beam12", "Beam13", "Beam14", "Beam15", "Beam16", "Beam17", "Beam18", "Beam19", "Beam2", "Beam20", "Beam21", "Beam22", "Beam23", "Beam24", "Beam25", "Beam26", "Beam27", "Beam3", "Beam4", "Beam5", "Beam6", "Beam7", "Beam8", "Beam9", "LeftEyeTrail", "RightEyeTrail" }, CatalogStatus = "NEEDS_OPTIMIZATION" },
	char_sanjo_base = { SourceModelName = "TS SANJI", SourcePath = "One Piece Pack.TS SANJI" },
	char_yujo_base = { SourceModelName = "Yuji", SourcePath = "JJK.Yuji" },
	char_narotu_sage = { SourceModelName = "Sage Mode", SourcePath = "NARUTO.Sage Mode" },
	char_olmaito_mode = { SourceModelName = "All Might (MODE)", SourcePath = "My Hero Academia Pack.All Might (MODE)" },
	char_deko_full = { SourceModelName = "100% Deku", SourcePath = "My Hero Academia Pack.100% Deku", VFX = { Light = { "SaiyanAura" }, Full = { "SaiyanAura" } }, VFXExcluded = { "ShootParticle", "SmallShoot" } },
	char_vegitto_base = { SourceModelName = "VEGITO", SourcePath = "DBZ.Vegito.VEGITO" },
	char_aizo_base = { SourceModelName = "Aizen", SourcePath = "Bleach Pack.Aizen.Aizen", VFXExcluded = { "Trail" } },
	char_brolli_legend = { SourceModelName = "LSSJ BROLY", SourcePath = "DBZ.Broly.LSSJ BROLY", VFX = { Light = { "SaiyanAura" }, Full = { "SaiyanAura", "SaiyanAura2" } } },
	char_madaro_base = { SourceModelName = "Madara", SourcePath = "NARUTO.Madara" },
	char_ichiro_mugetsu = { SourceModelName = "Mugetsu", SourcePath = "Bleach Pack.Hollow Ichigo.Mugetsu", VFX = { Light = { "BlackFlame" }, Full = { "BlackFlame" } } },
	char_mighto_gate8 = { SourceModelName = "8TH GATE", SourcePath = "NARUTO.Might Guy.8TH GATE", VFX = { Light = { "Aura" }, Full = { "Aura", "ParticleEmitter" } }, VFXExcluded = { "Beam1", "Beam10", "Beam11", "Beam12", "Beam13", "Beam14", "Beam15", "Beam16", "Beam17", "Beam18", "Beam19", "Beam2", "Beam20", "Beam21", "Beam22", "Beam23", "Beam24", "Beam25", "Beam26", "Beam27", "Beam28", "Beam3", "Beam4", "Beam5", "Beam6", "Beam7", "Beam8", "Beam9", "LeftEyeTrail", "RightEyeTrail" }, CatalogStatus = "NEEDS_OPTIMIZATION" },
	char_vegitto_blue = { SourceModelName = "VEGITO BLUE", SourcePath = "DBZ.Vegito.VEGITO BLUE", VFX = { Light = { "SaiyanAura" }, Full = { "SaiyanAura" } } },
	char_infernus_base = { SourceModelName = "Hellflame", SourcePath = "My Hero Academia Pack.Hellflame", VFX = { Light = { "Particle1" }, Full = { "Particle1" } } },
	char_iskander_base = { SourceModelName = "Iskandar", SourcePath = "FATE.Iskandar" },
	char_kizaro_base = { SourceModelName = "Kizaru", SourcePath = "One Piece Pack.Kizaru" },
	char_lanseiro_mode = { SourceModelName = "Lancer Mode", SourcePath = "FATE.Lancer Mode", VFX = { Light = { "Reiatsu" }, Full = { "Reiatsu" } }, VFXExcluded = { "ChargeParticle", "ChargeParticle2", "ShootParticle", "Trail", "Trail1", "Trail2" } },
	char_samurai_afro_base = { SourceModelName = "Afro Samurai", SourcePath = "OTHER.MISC.Afro Samurai", VFX = { Light = { "ParticleEmitter" }, Full = { "ParticleEmitter" } }, VFXExcluded = { "Beam" } },
	char_goko_dark_rose = { SourceModelName = "SSJR", SourcePath = "DBZ.Goku Black.SSJR", VFX = { Light = { "FinAura2" }, Full = { "FinAura2", "Particle" } } },
	char_yoruka_shunko = { SourceModelName = "Shunko Yoruichi", SourcePath = "Bleach Pack.Yoruichi.Shunko Yoruichi", VFX = { Light = { "Shunko1" }, Full = { "Shunko1", "Shunko2", "Shunko3", "Shunko4" } } },
	char_seiba_alter = { SourceModelName = "SALTER", SourcePath = "FATE.SALTER", VFXExcluded = { "Charge" } },
	char_toshiru_bankai = { SourceModelName = "Bankai Toshiro", SourcePath = "Bleach Pack.Toshiro.Bankai Toshiro", VFX = { Light = { "Twirl1" }, Full = { "Twirl1", "Twirl2" } }, VFXExcluded = { "Trail" } },
}
for id, spec in launchAssets do
	assert(CharacterAssetConfig.Assets[id] == nil, "asset repetido: " .. id)
	CharacterAssetConfig.Assets[id] = spec
end
-- END LAUNCH CATALOG

local byId = CharacterAssetConfig.Assets

-- Multiplicador visual final (limitado) de um personagem
function CharacterAssetConfig.visualScale(characterId: string): number
	local entry = byId[characterId]
	local value = entry and entry.VisualScale or 1
	local limits = CharacterAssetConfig.VisualScaleLimits
	return math.clamp(value, limits.Min, limits.Max)
end

-- {x, y, z} (studs normalizados); {0, 0, 0} quando não há ajuste
function CharacterAssetConfig.visualOffset(characterId: string): { number }
	local entry = byId[characterId]
	return entry and entry.VisualOffset or { 0, 0, 0 }
end

return CharacterAssetConfig
