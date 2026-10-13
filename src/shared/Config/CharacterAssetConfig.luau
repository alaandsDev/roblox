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

	FASE PILOTO: só os personagens de Assets existem (metadados em CharacterConfig.Pilots).
	Eles NÃO entram no roll (RollCore usa
	CharacterConfig.List), nem no progresso do Índice; aparecem via DEV (GiveCharacter,
	PlayReveal, CharacterGallery) para validar o pipeline no Studio antes do lote de 121.
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

--[[
	Correção de ROUPA por id de template (genérica: vale para todo personagem que usar o mesmo id).
	Alguns modelos do pack apontam o ShirtTemplate/PantsTemplate para o ITEM da loja (Shirt/Pants)
	em vez da IMAGEM do template — o Roblox não desenha nada e o personagem aparece sem roupa.
	O comando DEV ClothingCheck (Studio, Play, servidor) descobre a imagem certa e imprime as
	linhas prontas para colar aqui. Chave = id do pack (string); valor = template final.
]]
CharacterAssetConfig.ClothingTemplateOverrides = {} :: { [string]: string }

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
-- Metadados de jogo (nome, raridade, família, stats) ficam em CharacterConfig.Pilots.
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
