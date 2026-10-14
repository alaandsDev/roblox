--!strict
--[[
	ROSTER = catálogo de LANÇAMENTO (121, gerado por tools/characters/gen_launch_catalog.py):
	    List    = 112 F2P (coleção principal do Índice; cada um em EXATAMENTE um dos 16 Dice,
	              campo DefaultDice; o roll é por Dice: DiceCore)
	    Premium = 9 (LaunchPool = "Premium"): fora dos Dice F2P, progresso próprio no Índice (x/9)
	    Launch  = os 121
	    Legacy  = os 24 lutadores originais da fase de protótipo (abaixo): NÃO são sorteados nem
	              contam no Índice; continuam em ById para perfis temporários antigos e fixtures.
	CharacterId é a chave persistente (DisplayName nunca vai para o save).

	Lutadores LEGADOS (24):

	BaseIncome = dinheiro por segundo quando colocado na base.
	BasePower  = força (usada nas Torres, fase futura).
	ModelName  = nome do modelo em ReplicatedStorage.Assets.Characters (quando existir);
	             até lá o CharacterModelFactory cria um placeholder 3D a partir do VisualTheme.
	VisualTheme:
	    Primary/Secondary/Skin: cores (RGB)
	    Headgear: None | Hood | Helmet | Spikes | Crown | Horns | Halo | Mask | Hat | Ears
	    Weapon:   None | Sword | Katana | Staff | Bow | Spear | Scythe | Hammer | Dagger | Fists | Shield
	    Wings:    true/false
	    Icon:     emoji usado nos cards da interface
	TODO_ASSET: substituir placeholders por modelos finais.

	Os 10 PILOTOS do pipeline de assets (abaixo) fazem parte do catálogo de lançamento (F2P,
	mesmos CharacterIds) e têm os metadados novos (DisplayName, SourceModelName, CharacterFamily,
	FormTier...), como os outros 111 gerados.
]]

export type Character = {
	Id: string,
	IndexNumber: number,
	Name: string,
	Rarity: string,
	BasePower: number,
	BaseIncome: number,
	-- Custo do nível 1 -> 2 da estação. nil = BaseIncome * CharacterLevelConfig.BaseCostSeconds
	BaseUpgradeCost: number?,
	ModelName: string,
	Description: string,
	VisualTheme: {
		Primary: { number },
		Secondary: { number },
		Skin: { number },
		Headgear: string,
		Weapon: string,
		Wings: boolean,
		Icon: string,
	},
	-- Metadados do pipeline de assets (nil nos 24 originais)
	DisplayName: string?,
	SourceModelName: string?,
	CharacterFamily: string?,
	FormTier: number?,
	SourceCategory: string?,
	DefaultDice: string?,
	TechnicalStatus: string?,
	Pilot: boolean?,
	-- Lutador do protótipo (fora do roll e do Índice)
	Legacy: boolean?,
	-- Catálogo de lançamento (121): pool (F2P | Premium) e marca de lançamento
	LaunchPool: string?,
	Launch: boolean?,
}

local SKIN_LIGHT = { 255, 214, 180 }
local SKIN_TAN = { 222, 170, 125 }
local SKIN_DARK = { 150, 100, 70 }
local SKIN_PALE = { 235, 235, 245 }

local function c(
	index: number,
	id: string,
	name: string,
	rarity: string,
	power: number,
	income: number,
	description: string,
	theme: any
): Character
	return {
		Id = id,
		IndexNumber = index,
		Name = name,
		Rarity = rarity,
		BasePower = power,
		BaseIncome = income,
		ModelName = id,
		Description = description,
		VisualTheme = theme,
	}
end

local list: { Character } = {
	-- Comuns
	c(1, "flame_rookie", "Flame Rookie", "Common", 12, 1, "Um recruta esquentado que aprendeu a acender a espada antes de aprender a segurá-la.",
		{ Primary = { 230, 80, 50 }, Secondary = { 60, 50, 50 }, Skin = SKIN_LIGHT, Headgear = "Spikes", Weapon = "Sword", Wings = false, Icon = "🔥" }),
	c(2, "wind_disciple", "Wind Disciple", "Common", 10, 1, "Treina no topo das montanhas e chega sempre antes do vento.",
		{ Primary = { 140, 220, 200 }, Secondary = { 240, 240, 240 }, Skin = SKIN_TAN, Headgear = "Hood", Weapon = "Staff", Wings = false, Icon = "🌪️" }),
	c(3, "stone_brawler", "Stone Brawler", "Common", 16, 2, "Punhos de granito, paciência de pedra-pomes.",
		{ Primary = { 140, 120, 100 }, Secondary = { 90, 80, 70 }, Skin = SKIN_DARK, Headgear = "None", Weapon = "Fists", Wings = false, Icon = "🪨" }),
	c(4, "spark_cadet", "Spark Cadet", "Common", 14, 2, "Cadete da guarda-relâmpago; ainda leva choque da própria lança.",
		{ Primary = { 250, 220, 70 }, Secondary = { 50, 60, 90 }, Skin = SKIN_LIGHT, Headgear = "Helmet", Weapon = "Spear", Wings = false, Icon = "⚡" }),
	c(5, "tide_apprentice", "Tide Apprentice", "Common", 11, 1, "Aprendiz das marés: suas magias molham mais do que machucam.",
		{ Primary = { 60, 140, 230 }, Secondary = { 230, 240, 255 }, Skin = SKIN_TAN, Headgear = "Hat", Weapon = "Staff", Wings = false, Icon = "🌊" }),

	-- Incomuns
	c(6, "shadow_scout", "Shadow Scout", "Uncommon", 45, 3, "Batedor das sombras. Você só percebe que ele passou pelo bilhete que ele deixou.",
		{ Primary = { 50, 45, 70 }, Secondary = { 150, 60, 200 }, Skin = SKIN_PALE, Headgear = "Mask", Weapon = "Dagger", Wings = false, Icon = "🥷" }),
	c(7, "ember_archer", "Ember Archer", "Uncommon", 50, 4, "Flechas que viram brasas no meio do caminho.",
		{ Primary = { 200, 90, 40 }, Secondary = { 120, 70, 40 }, Skin = SKIN_LIGHT, Headgear = "Hood", Weapon = "Bow", Wings = false, Icon = "🏹" }),
	c(8, "iron_guardian", "Iron Guardian", "Uncommon", 58, 5, "Guardião de ferro: nunca recuou, nunca enferrujou.",
		{ Primary = { 170, 175, 185 }, Secondary = { 60, 90, 160 }, Skin = SKIN_TAN, Headgear = "Helmet", Weapon = "Shield", Wings = false, Icon = "🛡️" }),
	c(9, "leaf_ranger", "Leaf Ranger", "Uncommon", 44, 3, "Patrulheira da floresta, fala com árvores (e elas respondem).",
		{ Primary = { 80, 170, 70 }, Secondary = { 120, 90, 50 }, Skin = SKIN_LIGHT, Headgear = "Ears", Weapon = "Bow", Wings = false, Icon = "🍃" }),

	-- Raros
	c(10, "storm_swordsman", "Storm Swordsman", "Rare", 150, 8, "Espadachim que corta trovões ao meio.",
		{ Primary = { 70, 90, 180 }, Secondary = { 250, 230, 90 }, Skin = SKIN_LIGHT, Headgear = "Spikes", Weapon = "Katana", Wings = false, Icon = "🌩️" }),
	c(11, "frost_assassin", "Frost Assassin", "Rare", 165, 9, "Assassina do gelo eterno. O frio chega antes da lâmina.",
		{ Primary = { 180, 230, 255 }, Secondary = { 60, 90, 140 }, Skin = SKIN_PALE, Headgear = "Hood", Weapon = "Dagger", Wings = false, Icon = "❄️" }),
	c(12, "crystal_mage", "Crystal Mage", "Rare", 140, 11, "Maga que guarda feitiços dentro de cristais.",
		{ Primary = { 210, 120, 255 }, Secondary = { 255, 255, 255 }, Skin = SKIN_LIGHT, Headgear = "Hat", Weapon = "Staff", Wings = false, Icon = "🔮" }),
	c(13, "thunder_monk", "Thunder Monk", "Rare", 175, 10, "Monge que medita no meio de tempestades.",
		{ Primary = { 255, 170, 40 }, Secondary = { 120, 60, 30 }, Skin = SKIN_TAN, Headgear = "None", Weapon = "Fists", Wings = false, Icon = "🥋" }),

	-- Épicos
	c(14, "cyber_ronin", "Cyber Ronin", "Epic", 560, 22, "Samurai sem mestre de uma cidade neon do futuro.",
		{ Primary = { 30, 30, 40 }, Secondary = { 0, 255, 220 }, Skin = SKIN_PALE, Headgear = "Mask", Weapon = "Katana", Wings = false, Icon = "🤖" }),
	c(15, "blood_moon_hunter", "Blood Moon Hunter", "Epic", 640, 25, "Caçadora que só aparece em noites de lua vermelha.",
		{ Primary = { 140, 20, 40 }, Secondary = { 30, 20, 30 }, Skin = SKIN_PALE, Headgear = "Hat", Weapon = "Scythe", Wings = false, Icon = "🌕" }),
	c(16, "tempest_valkyrie", "Tempest Valkyrie", "Epic", 600, 28, "Guerreira alada que cavalga as tempestades.",
		{ Primary = { 230, 230, 245 }, Secondary = { 90, 160, 255 }, Skin = SKIN_LIGHT, Headgear = "Helmet", Weapon = "Spear", Wings = true, Icon = "🪽" }),

	-- Lendários
	c(17, "dragon_knight", "Dragon Knight", "Legendary", 2400, 55, "Cavaleiro que fez um pacto com o último dragão vermelho.",
		{ Primary = { 180, 30, 30 }, Secondary = { 230, 190, 60 }, Skin = SKIN_TAN, Headgear = "Horns", Weapon = "Sword", Wings = true, Icon = "🐉" }),
	c(18, "solar_paladin", "Solar Paladin", "Legendary", 2600, 62, "Paladino que carrega o sol do meio-dia no martelo.",
		{ Primary = { 255, 215, 90 }, Secondary = { 255, 255, 240 }, Skin = SKIN_LIGHT, Headgear = "Halo", Weapon = "Hammer", Wings = false, Icon = "☀️" }),
	c(19, "abyss_warlock", "Abyss Warlock", "Legendary", 2300, 70, "Bruxo que negocia com o que mora no fundo do abismo.",
		{ Primary = { 40, 20, 70 }, Secondary = { 120, 255, 160 }, Skin = SKIN_PALE, Headgear = "Horns", Weapon = "Staff", Wings = false, Icon = "🕳️" }),

	-- Míticos
	c(20, "void_emperor", "Void Emperor", "Mythic", 12000, 150, "Imperador de um reino que já não existe. O vazio obedece à sua coroa.",
		{ Primary = { 25, 15, 45 }, Secondary = { 170, 80, 255 }, Skin = SKIN_PALE, Headgear = "Crown", Weapon = "Scythe", Wings = false, Icon = "👑" }),
	c(21, "celestial_monk", "Celestial Monk", "Mythic", 13000, 170, "Monge que alcançou as estrelas meditando.",
		{ Primary = { 255, 245, 220 }, Secondary = { 255, 190, 80 }, Skin = SKIN_TAN, Headgear = "Halo", Weapon = "Fists", Wings = false, Icon = "🌟" }),

	-- Divinos
	c(22, "astral_seraph", "Astral Seraph", "Divine", 58000, 400, "Serafim que guarda a passagem entre as galáxias.",
		{ Primary = { 255, 255, 255 }, Secondary = { 120, 200, 255 }, Skin = SKIN_PALE, Headgear = "Halo", Weapon = "Spear", Wings = true, Icon = "😇" }),
	c(23, "chrono_sage", "Chrono Sage", "Divine", 62000, 450, "Sábio que lembra do futuro e esquece o passado.",
		{ Primary = { 60, 200, 190 }, Secondary = { 255, 220, 120 }, Skin = SKIN_TAN, Headgear = "Hat", Weapon = "Staff", Wings = false, Icon = "⏳" }),

	-- Secreto
	c(24, "eclipse_sovereign", "Eclipse Sovereign", "Secret", 320000, 1200, "Ninguém sabe de onde veio. Só aparece quando o sol e a lua param para olhar.",
		{ Primary = { 15, 10, 20 }, Secondary = { 255, 120, 40 }, Skin = SKIN_DARK, Headgear = "Crown", Weapon = "Scythe", Wings = true, Icon = "🌑" }),
}

local byId: { [string]: Character } = {}
for _, character in list do
	assert(byId[character.Id] == nil, "personagem repetido: " .. character.Id)
	character.Legacy = true
	byId[character.Id] = character
end

-- PILOTO do pipeline de assets (ids próprios e estáveis; ver CharacterAssetConfig / CHARACTER_PIPELINE.md)
local function pilot(index: number, id: string, displayName: string, sourceModelName: string, rarity: string, family: string, formTier: number, category: string, dice: string, power: number, income: number, icon: string, description: string): Character
	return {
		Id = id,
		IndexNumber = index,
		Name = displayName,
		Rarity = rarity,
		BasePower = power,
		BaseIncome = income,
		ModelName = id,
		Description = description,
		-- Cores do placeholder (fallback quando o asset não existe)
		VisualTheme = { Primary = { 90, 90, 110 }, Secondary = { 200, 200, 215 }, Skin = SKIN_LIGHT, Headgear = "None", Weapon = "None", Wings = false, Icon = icon },
		DisplayName = displayName,
		SourceModelName = sourceModelName,
		CharacterFamily = family,
		FormTier = formTier,
		SourceCategory = category,
		DefaultDice = dice,
		TechnicalStatus = "APPROVED",
		Pilot = true,
		LaunchPool = "F2P",
		Launch = true,
	}
end

-- Personagem do catálogo de lançamento (gerado a partir de third_party/catalog_proposal.json)
local function launch(index: number, id: string, displayName: string, sourceModelName: string, rarity: string, family: string, formTier: number, category: string, dice: string, pool: string, status: string, power: number, income: number): Character
	return {
		Id = id,
		IndexNumber = index,
		Name = displayName,
		Rarity = rarity,
		BasePower = power,
		BaseIncome = income,
		ModelName = id,
		Description = "",
		VisualTheme = { Primary = { 90, 90, 110 }, Secondary = { 200, 200, 215 }, Skin = SKIN_LIGHT, Headgear = "None", Weapon = "None", Wings = false, Icon = if pool == "Premium" then "💎" else "🎲" },
		DisplayName = displayName,
		SourceModelName = sourceModelName,
		CharacterFamily = family,
		FormTier = formTier,
		SourceCategory = category,
		DefaultDice = dice, -- DiceAssignment planejado (só metadado nesta fase)
		TechnicalStatus = status,
		LaunchPool = pool,
		Launch = true,
	}
end

local pilots: { Character } = {
	pilot(901, "char_sacha_base", "Sacha", "Sasha", "Common", "sacha", 1, "AOT", "starter", 12, 1, "🥔",
		"Recruta da tropa de exploração. Nunca recusa um lanche."),
	pilot(902, "char_ichiro_base", "Ichiro", "Ichigo", "Uncommon", "ichiro", 1, "Bleach Pack", "blade", 50, 4, "🗡️",
		"Substituto de ceifador com uma espada maior que ele."),
	pilot(903, "char_ichiro_hollow", "Ichiro Mascarado", "Hollow Ichigo", "Mythic", "ichiro", 2, "Bleach Pack", "shadow", 12500, 160, "👹",
		"A máscara assumiu o controle. A espada ficou ainda mais pesada."),
	pilot(904, "char_goko_base", "Goko", "Goku", "Uncommon", "goko", 1, "DBZ", "fighter", 48, 4, "🥋",
		"Treina o dia inteiro e come o dobro disso."),
	pilot(905, "char_barbalva_base", "Barbalva", "Whitebeard", "Mythic", "barbalva", 1, "One Piece Pack", "forbidden", 13000, 170, "🏴‍☠️",
		"Capitão lendário. O mar treme quando ele dá risada."),
	pilot(906, "char_killuo_base", "Killuo", "Killua", "Rare", "killuo", 1, "HXH", "storm", 155, 9, "⚡",
		"Assassino aposentado aos 12 anos. Ainda gosta de chocolate."),
	pilot(907, "char_killuo_godspeed", "Killuo Relâmpago", "Killua Godspeed", "Legendary", "killuo", 2, "HXH", "storm", 2450, 60, "🌩️",
		"Tão rápido que o trovão chega depois."),
	pilot(908, "char_zabuzo_base", "Zabuzo", "Zabuza", "Rare", "zabuzo", 1, "NARUTO", "shinobi", 160, 9, "🌫️",
		"Espadachim da névoa com uma espada do tamanho de uma porta."),
	pilot(909, "char_yamamotu_base", "Yamamotu", "Yamamoto", "Epic", "yamamotu", 1, "Bleach Pack", "flame", 600, 25, "🔥",
		"Capitão-comandante. A bengala esconde uma espada de fogo."),
	pilot(910, "char_goju_base", "Goju", "Gojo Satoru", "Divine", "goju", 1, "JJK", "celestial", 60000, 425, "🕶️",
		"O mais forte. Usa venda nos olhos por estilo."),
}
for _, character in pilots do
	assert(byId[character.Id] == nil, "personagem repetido: " .. character.Id)
	byId[character.Id] = character
end

-- BEGIN LAUNCH CATALOG (gerado por tools/characters/gen_launch_catalog.py — não editar à mão)
-- Personagens de LANÇAMENTO (121 = 112 F2P + 9 Premium). F2P = roster do roll (por Dice,
-- campo DefaultDice) e da coleção do Índice; Premium fora dos Dice. Poder por raridade; renda F2P = IncomeCurve (0 aqui).
local launchGenerated: { Character } = {
	launch(1000, "char_anny_school", "Anny (Colegial)", "Annie (Junior High)", "Common", "anny", 1, "AOT", "starter", "F2P", "APPROVED", 12, 0),
	launch(1001, "char_mikaza_formal", "Mikaza (Formal)", "Mikasa (Formal)", "Common", "mikaza", 1, "AOT", "starter", "F2P", "APPROVED", 12, 0),
	launch(1003, "char_sacha_suit", "Sacha (Terno)", "Sasha (Suit)", "Common", "sacha", 1, "AOT", "starter", "F2P", "APPROVED", 12, 0),
	launch(1004, "char_chiko_base", "Chiko", "Chika", "Uncommon", "chiko", 1, "OTHER", "starter", "F2P", "APPROVED", 50, 0),
	launch(1005, "char_erwyn_gala", "Erwyn (Gala)", "Erwin (Alt)", "Uncommon", "erwyn", 1, "AOT", "starter", "F2P", "APPROVED", 50, 0),
	launch(1006, "char_kurilo_base", "Kurilo", "Krillin", "Rare", "kurilo", 1, "DBZ", "starter", "F2P", "APPROVED", 155, 0),
	launch(1007, "char_saitano_base", "Saitano", "Saitama", "Epic", "saitano", 1, "OTHER", "starter", "F2P", "APPROVED", 600, 0),
	launch(1008, "char_gom_base", "Gom", "Gon", "Common", "gom", 1, "HXH", "lucky", "F2P", "APPROVED", 12, 0),
	launch(1009, "char_sanjo_young", "Sanjo (Jovem)", "ptsSanji", "Common", "sanjo", 1, "One Piece Pack", "lucky", "F2P", "APPROVED", 12, 0),
	launch(1010, "char_kazumo_base", "Kazumo", "Kazuma", "Uncommon", "kazumo", 1, "OTHER", "lucky", "F2P", "APPROVED", 50, 0),
	launch(1011, "char_rinn_base", "Rinn", "Rin", "Uncommon", "rinn", 1, "FATE", "lucky", "F2P", "APPROVED", 50, 0),
	launch(1012, "char_grei_base", "Grei", "Gray", "Rare", "grei", 1, "Fairy Tail", "lucky", "F2P", "APPROVED", 155, 0),
	launch(1013, "char_rukya_base", "Rukya", "Rukia", "Rare", "rukya", 1, "Bleach Pack", "lucky", "F2P", "APPROVED", 155, 0),
	launch(1014, "char_hizoka_base", "Hizoka", "Hisoka", "Epic", "hizoka", 1, "HXH", "lucky", "F2P", "APPROVED", 600, 0),
	launch(1015, "char_erem_base", "Erem", "Eren", "Common", "erem", 1, "AOT", "rampart", "F2P", "APPROVED", 12, 0),
	launch(1016, "char_anny_base", "Anny", "Annie", "Uncommon", "anny", 1, "AOT", "rampart", "F2P", "APPROVED", 50, 0),
	launch(1017, "char_mikaza_base", "Mikaza", "Mikasa", "Uncommon", "mikaza", 1, "AOT", "rampart", "F2P", "APPROVED", 50, 0),
	launch(1018, "char_erem_veteran", "Erem (Veterano)", "Eren Post-time skip", "Rare", "erem", 2, "AOT", "rampart", "F2P", "APPROVED", 155, 0),
	launch(1019, "char_erwyn_base", "Erwyn", "Erwin", "Rare", "erwyn", 1, "AOT", "rampart", "F2P", "APPROVED", 155, 0),
	launch(1020, "char_anny_titan", "Titã Feminina", "Female Titan", "Epic", "anny", 2, "AOT", "rampart", "F2P", "APPROVED", 600, 0),
	launch(1021, "char_erem_titan", "Titã de Ataque", "Attack Titan", "Epic", "erem", 3, "AOT", "rampart", "F2P", "APPROVED", 600, 0),
	launch(1022, "char_natzu_base", "Natzu", "Natsu", "Uncommon", "natzu", 1, "Fairy Tail", "flame", "F2P", "APPROVED", 50, 0),
	launch(1023, "char_todoruki_base", "Todoruki", "Todoroki", "Uncommon", "todoruki", 1, "My Hero Academia Pack", "flame", "F2P", "APPROVED", 50, 0),
	launch(1024, "char_ase_base", "Ase", "Ace", "Rare", "ase", 1, "One Piece Pack", "flame", "F2P", "APPROVED", 155, 0),
	launch(1025, "char_bakugu_base", "Bakugu", "Bakugo", "Rare", "bakugu", 1, "My Hero Academia Pack", "flame", "F2P", "APPROVED", 155, 0),
	launch(1027, "char_akaino_base", "Akaino", "Akainu", "Legendary", "akaino", 1, "One Piece Pack", "flame", "F2P", "APPROVED", 2450, 0),
	launch(1028, "char_narotu_young", "Narotu (Jovem)", "ptsNaruto", "Common", "narotu", 1, "NARUTO", "shinobi", "F2P", "APPROVED", 12, 0),
	launch(1029, "char_sasuko_young", "Sasuko (Jovem)", "ptsSasuke", "Common", "sasuko", 1, "NARUTO", "shinobi", "F2P", "APPROVED", 12, 0),
	launch(1030, "char_nejo_base", "Nejo", "Neji", "Uncommon", "nejo", 1, "NARUTO", "shinobi", "F2P", "APPROVED", 50, 0),
	launch(1031, "char_roqueli_base", "Roque Li", "Rock Lee", "Uncommon", "roqueli", 1, "NARUTO", "shinobi", "F2P", "APPROVED", 50, 0),
	launch(1032, "char_gaaro_base", "Gaaro", "Gaara", "Rare", "gaaro", 1, "NARUTO", "shinobi", "F2P", "APPROVED", 155, 0),
	launch(1034, "char_kakaxi_base", "Kakaxi", "Kakashi", "Epic", "kakaxi", 1, "NARUTO", "shinobi", "F2P", "APPROVED", 600, 0),
	launch(1035, "char_narotu_base", "Narotu", "tsNaruto", "Epic", "narotu", 2, "NARUTO", "shinobi", "F2P", "APPROVED", 600, 0),
	launch(1037, "char_zoru_young", "Zoru (Jovem)", "ptsZoro", "Uncommon", "zoru", 1, "One Piece Pack", "blade", "F2P", "APPROVED", 50, 0),
	launch(1038, "char_ginn_base", "Ginn", "Gin", "Rare", "ginn", 1, "Bleach Pack", "blade", "F2P", "APPROVED", 155, 0),
	launch(1039, "char_kisuko_base", "Kisuko", "Kisuke", "Rare", "kisuko", 1, "Bleach Pack", "blade", "F2P", "APPROVED", 155, 0),
	launch(1040, "char_trunkz_base", "Trunkz", "Trunks", "Rare", "trunkz", 1, "DBZ", "blade", "F2P", "APPROVED", 155, 0),
	launch(1041, "char_tanjiru_base", "Tanjiru", "Tanjiro", "Epic", "tanjiru", 1, "OTHER", "blade", "F2P", "APPROVED", 600, 0),
	launch(1042, "char_zoru_base", "Zoru", "tsZoro", "Epic", "zoru", 2, "One Piece Pack", "blade", "F2P", "APPROVED", 600, 0),
	launch(1043, "char_shankz_base", "Shankz", "Shanks", "Legendary", "shankz", 1, "One Piece Pack", "blade", "F2P", "APPROVED", 2450, 0),
	launch(1044, "char_deko_base", "Deko", "Deku", "Uncommon", "deko", 1, "My Hero Academia Pack", "fighter", "F2P", "APPROVED", 50, 0),
	launch(1046, "char_yuzuke_base", "Yuzuke", "Yusuke", "Uncommon", "yuzuke", 1, "YYH", "fighter", "F2P", "APPROVED", 50, 0),
	launch(1047, "char_lemilio_base", "Lemilio", "Lemillion", "Rare", "lemilio", 1, "My Hero Academia Pack", "fighter", "F2P", "APPROVED", 155, 0),
	launch(1048, "char_lufy_base", "Lufy", "tsLuffy", "Rare", "lufy", 2, "One Piece Pack", "fighter", "F2P", "APPROVED", 155, 0),
	launch(1049, "char_pikkolo_base", "Pikkolo", "Piccolo", "Epic", "pikkolo", 1, "DBZ", "fighter", "F2P", "APPROVED", 600, 0),
	launch(1050, "char_olmaito_base", "Ol Maito", "All Might", "Legendary", "olmaito", 1, "My Hero Academia Pack", "fighter", "F2P", "APPROVED", 2450, 0),
	launch(1052, "char_lanseiro_base", "Lanseiro", "Lancer", "Rare", "lanseiro", 1, "FATE", "storm", "F2P", "APPROVED", 155, 0),
	launch(1053, "char_minatu_base", "Minatu", "Minato", "Rare", "minatu", 1, "NARUTO", "storm", "F2P", "APPROVED", 155, 0),
	launch(1054, "char_goko_majin_saga", "Goko (Saga Majin)", "Buu Saga Goku", "Epic", "goko", 2, "DBZ", "storm", "F2P", "APPROVED", 600, 0),
	launch(1055, "char_kaulifa_base", "Kaulifa", "Caulifa", "Epic", "kaulifa", 1, "DBZ", "storm", "F2P", "APPROVED", 600, 0),
	launch(1056, "char_deko_awakened", "Deko Desperto", "Deku Awakened", "Legendary", "deko", 2, "My Hero Academia Pack", "storm", "F2P", "APPROVED", 2450, 0),
	launch(1058, "char_toshiru_base", "Toshiru", "Toshiro", "Rare", "toshiru", 1, "Bleach Pack", "spirit", "F2P", "APPROVED", 155, 0),
	launch(1059, "char_byakuto_base", "Byakuto", "Byakuya", "Epic", "byakuto", 1, "Bleach Pack", "spirit", "F2P", "APPROVED", 600, 0),
	launch(1060, "char_shunzo_base", "Shunzo", "Shunsui", "Epic", "shunzo", 1, "Bleach Pack", "spirit", "F2P", "APPROVED", 600, 0),
	launch(1061, "char_starko_base", "Starko", "Starrk", "Epic", "starko", 1, "Bleach Pack", "spirit", "F2P", "APPROVED", 600, 0),
	launch(1062, "char_hiey_base", "Hiey", "Hiei", "Legendary", "hiey", 1, "YYH", "spirit", "F2P", "APPROVED", 2450, 0),
	launch(1063, "char_yoruka_base", "Yoruka", "Yoruichi", "Legendary", "yoruka", 1, "Bleach Pack", "spirit", "F2P", "APPROVED", 2450, 0),
	launch(1064, "char_yuzuke_demon", "Yuzuke Demônio", "Yusuke Mode", "Mythic", "yuzuke", 2, "YYH", "spirit", "F2P", "APPROVED", 12500, 0),
	launch(1065, "char_kiritsugo_base", "Kiritsugo", "Kiritsugu", "Rare", "kiritsugo", 1, "FATE", "arcane", "F2P", "APPROVED", 155, 0),
	launch(1066, "char_seiba_base", "Seiba", "Saber", "Rare", "seiba", 1, "FATE", "arcane", "F2P", "APPROVED", 155, 0),
	launch(1067, "char_shiro_base", "Shiro", "Shirou", "Rare", "shiro", 1, "FATE", "arcane", "F2P", "APPROVED", 155, 0),
	launch(1068, "char_akcel_base", "Akcel", "Accel", "Epic", "akcel", 1, "OTHER", "arcane", "F2P", "APPROVED", 600, 0),
	launch(1069, "char_lau_base", "Lau", "ptsLaw", "Epic", "lau", 1, "One Piece Pack", "arcane", "F2P", "APPROVED", 600, 0),
	launch(1070, "char_rika_base", "Rika", "Rikka", "Epic", "rika", 1, "OTHER", "arcane", "F2P", "APPROVED", 600, 0),
	launch(1071, "char_gilgamex_base", "Gilgamex", "Gilgamesh", "Legendary", "gilgamex", 1, "FATE", "arcane", "F2P", "APPROVED", 2450, 0),
	launch(1072, "char_shiro_archer", "Emyia Arqueiro", "Archer (EMIYA)", "Mythic", "shiro", 2, "FATE", "arcane", "F2P", "APPROVED", 12500, 0),
	launch(1073, "char_grimjau_base", "Grimjau", "Grimmjow", "Epic", "grimjau", 1, "Bleach Pack", "shadow", "F2P", "APPROVED", 600, 0),
	launch(1074, "char_shinjo_base", "Shinjo", "Shinji", "Epic", "shinjo", 1, "Bleach Pack", "shadow", "F2P", "APPROVED", 600, 0),
	launch(1075, "char_ulkiorra_base", "Ulkiorra", "Ulq", "Epic", "ulkiorra", 1, "Bleach Pack", "shadow", "F2P", "APPROVED", 600, 0),
	launch(1076, "char_itaxi_base", "Itaxi", "Itachi", "Legendary", "itaxi", 1, "NARUTO", "shadow", "F2P", "APPROVED", 2450, 0),
	launch(1077, "char_peinn_base", "Peinn", "Pain", "Legendary", "peinn", 1, "NARUTO", "shadow", "F2P", "APPROVED", 2450, 0),
	launch(1078, "char_goko_dark_base", "Goko Sombrio", "Goku Black [NEW]", "Mythic", "goko_dark", 1, "DBZ", "shadow", "F2P", "APPROVED", 12500, 0),
	launch(1080, "char_ilumi_base", "Ilumi", "Illumi", "Epic", "ilumi", 1, "HXH", "void", "F2P", "APPROVED", 600, 0),
	launch(1081, "char_vejita_base", "Vejita", "Vegeta", "Epic", "vejita", 1, "DBZ", "void", "F2P", "NEEDS_OPTIMIZATION", 600, 0),
	launch(1082, "char_ilumi_awakened", "Ilumi Desperto", "Illumi Awakened", "Legendary", "ilumi", 2, "HXH", "void", "F2P", "APPROVED", 2450, 0),
	launch(1083, "char_vejita_majin", "Vejita Majin", "Majin Vegeta", "Legendary", "vejita", 2, "DBZ", "void", "F2P", "APPROVED", 2450, 0),
	launch(1084, "char_ulkiorra_release", "Ulkiorra Liberado", "R1", "Mythic", "ulkiorra", 2, "Bleach Pack", "void", "F2P", "APPROVED", 12500, 0),
	launch(1085, "char_ichiro_vasto", "Ichiro Vasto", "Vasto", "Divine", "ichiro", 3, "Bleach Pack", "void", "F2P", "APPROVED", 60000, 0),
	launch(1086, "char_bakugu_awakened", "Bakugu Desperto", "Awakened Bakugo", "Legendary", "bakugu", 2, "My Hero Academia Pack", "awakened", "F2P", "APPROVED", 2450, 0),
	launch(1087, "char_grei_awakened", "Grei Desperto", "Grey Awakening", "Legendary", "grei", 2, "Fairy Tail", "awakened", "F2P", "APPROVED", 2450, 0),
	launch(1088, "char_rika_awakened", "Rika Desperta", "Rikka Awakened", "Legendary", "rika", 2, "OTHER", "awakened", "F2P", "APPROVED", 2450, 0),
	launch(1089, "char_gom_adult", "Gom Adulto", "Adult Gon", "Mythic", "gom", 2, "HXH", "awakened", "F2P", "APPROVED", 12500, 0),
	launch(1090, "char_natzu_awakened", "Natzu Desperto", "Natsu Awakened", "Mythic", "natzu", 2, "Fairy Tail", "awakened", "F2P", "APPROVED", 12500, 0),
	launch(1091, "char_roqueli_gates", "Roque Li dos Portões", "ROCK LEE GATES", "Mythic", "roqueli", 2, "NARUTO", "awakened", "F2P", "APPROVED", 12500, 0),
	launch(1092, "char_gohin_base", "Gohin", "Gohan", "Epic", "gohin", 1, "DBZ", "colossus", "F2P", "APPROVED", 600, 0),
	launch(1093, "char_mighto_base", "Mighto", "Might Guy", "Epic", "mighto", 1, "NARUTO", "colossus", "F2P", "APPROVED", 600, 0),
	launch(1094, "char_brolli_base", "Brolli", "Broly", "Legendary", "brolli", 1, "DBZ", "colossus", "F2P", "APPROVED", 2450, 0),
	launch(1095, "char_sasuko_base", "Sasuko", "tsSasuke", "Legendary", "sasuko", 2, "NARUTO", "colossus", "F2P", "APPROVED", 2450, 0),
	launch(1096, "char_lufy_snake", "Lufy Serpente", "Snakeman", "Mythic", "lufy", 3, "One Piece Pack", "colossus", "F2P", "APPROVED", 12500, 0),
	launch(1097, "char_mighto_gate5", "Mighto 5º Portão", "5TH GATE", "Mythic", "mighto", 2, "NARUTO", "colossus", "F2P", "NEEDS_OPTIMIZATION", 12500, 0),
	launch(1098, "char_sanjo_base", "Sanjo", "TS SANJI", "Legendary", "sanjo", 2, "One Piece Pack", "celestial", "F2P", "APPROVED", 2450, 0),
	launch(1099, "char_yujo_base", "Yujo", "Yuji", "Legendary", "yujo", 1, "JJK", "celestial", "F2P", "APPROVED", 2450, 0),
	launch(1100, "char_narotu_sage", "Narotu Sábio", "Sage Mode", "Mythic", "narotu", 3, "NARUTO", "celestial", "F2P", "APPROVED", 12500, 0),
	launch(1101, "char_olmaito_mode", "Ol Maito Poder Total", "All Might (MODE)", "Mythic", "olmaito", 2, "My Hero Academia Pack", "celestial", "F2P", "APPROVED", 12500, 0),
	launch(1102, "char_deko_full", "Deko 100%", "100% Deku", "Divine", "deko", 3, "My Hero Academia Pack", "celestial", "F2P", "APPROVED", 60000, 0),
	launch(1104, "char_vegitto_base", "Vegitto", "VEGITO", "Divine", "vegitto", 1, "DBZ", "celestial", "F2P", "APPROVED", 60000, 0),
	launch(1106, "char_aizo_base", "Aizo", "Aizen", "Divine", "aizo", 1, "Bleach Pack", "forbidden", "F2P", "APPROVED", 60000, 0),
	launch(1107, "char_brolli_legend", "Brolli Lendário", "LSSJ BROLY", "Divine", "brolli", 2, "DBZ", "forbidden", "F2P", "APPROVED", 60000, 0),
	launch(1108, "char_madaro_base", "Madaro", "Madara", "Divine", "madaro", 1, "NARUTO", "forbidden", "F2P", "APPROVED", 60000, 0),
	launch(1109, "char_ichiro_mugetsu", "Ichiro Mugetsu", "Mugetsu", "Secret", "ichiro", 4, "Bleach Pack", "forbidden", "F2P", "APPROVED", 320000, 0),
	launch(1110, "char_mighto_gate8", "Mighto 8º Portão", "8TH GATE", "Secret", "mighto", 3, "NARUTO", "forbidden", "F2P", "NEEDS_OPTIMIZATION", 320000, 0),
	launch(1111, "char_vegitto_blue", "Vegitto Azul", "VEGITO BLUE", "Secret", "vegitto", 2, "DBZ", "forbidden", "F2P", "APPROVED", 320000, 0),
	launch(1112, "char_infernus_base", "Infernus", "Hellflame", "Epic", "infernus", 1, "My Hero Academia Pack", "premium", "Premium", "APPROVED", 600, 25),
	launch(1113, "char_iskander_base", "Iskander", "Iskandar", "Epic", "iskander", 1, "FATE", "premium", "Premium", "APPROVED", 600, 25),
	launch(1114, "char_kizaro_base", "Kizaro", "Kizaru", "Legendary", "kizaro", 1, "One Piece Pack", "premium", "Premium", "APPROVED", 2450, 60),
	launch(1115, "char_lanseiro_mode", "Lanseiro Ardente", "Lancer Mode", "Legendary", "lanseiro", 2, "FATE", "premium", "Premium", "APPROVED", 2450, 60),
	launch(1116, "char_samurai_afro_base", "Samurai Afro", "Afro Samurai", "Legendary", "samurai_afro", 1, "OTHER", "premium", "Premium", "APPROVED", 2450, 60),
	launch(1117, "char_goko_dark_rose", "Goko Sombrio Rosé", "SSJR", "Mythic", "goko_dark", 2, "DBZ", "premium", "Premium", "APPROVED", 12500, 160),
	launch(1118, "char_yoruka_shunko", "Yoruka Shunko", "Shunko Yoruichi", "Mythic", "yoruka", 2, "Bleach Pack", "premium", "Premium", "APPROVED", 12500, 160),
	launch(1119, "char_seiba_alter", "Seiba Sombria", "SALTER", "Divine", "seiba", 2, "FATE", "premium", "Premium", "APPROVED", 60000, 425),
	launch(1120, "char_toshiru_bankai", "Toshiru Bankai", "Bankai Toshiro", "Secret", "toshiru", 2, "Bleach Pack", "premium", "Premium", "APPROVED", 320000, 1200),
}
-- Ordem do catálogo de lançamento (Dice, raridade, id); inclui os pilotos
local LAUNCH_ORDER: { string } = {
	"char_anny_school",
	"char_mikaza_formal",
	"char_sacha_base",
	"char_sacha_suit",
	"char_chiko_base",
	"char_erwyn_gala",
	"char_kurilo_base",
	"char_saitano_base",
	"char_gom_base",
	"char_sanjo_young",
	"char_kazumo_base",
	"char_rinn_base",
	"char_grei_base",
	"char_rukya_base",
	"char_hizoka_base",
	"char_erem_base",
	"char_anny_base",
	"char_mikaza_base",
	"char_erem_veteran",
	"char_erwyn_base",
	"char_anny_titan",
	"char_erem_titan",
	"char_natzu_base",
	"char_todoruki_base",
	"char_ase_base",
	"char_bakugu_base",
	"char_yamamotu_base",
	"char_akaino_base",
	"char_narotu_young",
	"char_sasuko_young",
	"char_nejo_base",
	"char_roqueli_base",
	"char_gaaro_base",
	"char_zabuzo_base",
	"char_kakaxi_base",
	"char_narotu_base",
	"char_ichiro_base",
	"char_zoru_young",
	"char_ginn_base",
	"char_kisuko_base",
	"char_trunkz_base",
	"char_tanjiru_base",
	"char_zoru_base",
	"char_shankz_base",
	"char_deko_base",
	"char_goko_base",
	"char_yuzuke_base",
	"char_lemilio_base",
	"char_lufy_base",
	"char_pikkolo_base",
	"char_olmaito_base",
	"char_killuo_base",
	"char_lanseiro_base",
	"char_minatu_base",
	"char_goko_majin_saga",
	"char_kaulifa_base",
	"char_deko_awakened",
	"char_killuo_godspeed",
	"char_toshiru_base",
	"char_byakuto_base",
	"char_shunzo_base",
	"char_starko_base",
	"char_hiey_base",
	"char_yoruka_base",
	"char_yuzuke_demon",
	"char_kiritsugo_base",
	"char_seiba_base",
	"char_shiro_base",
	"char_akcel_base",
	"char_lau_base",
	"char_rika_base",
	"char_gilgamex_base",
	"char_shiro_archer",
	"char_grimjau_base",
	"char_shinjo_base",
	"char_ulkiorra_base",
	"char_itaxi_base",
	"char_peinn_base",
	"char_goko_dark_base",
	"char_ichiro_hollow",
	"char_ilumi_base",
	"char_vejita_base",
	"char_ilumi_awakened",
	"char_vejita_majin",
	"char_ulkiorra_release",
	"char_ichiro_vasto",
	"char_bakugu_awakened",
	"char_grei_awakened",
	"char_rika_awakened",
	"char_gom_adult",
	"char_natzu_awakened",
	"char_roqueli_gates",
	"char_gohin_base",
	"char_mighto_base",
	"char_brolli_base",
	"char_sasuko_base",
	"char_lufy_snake",
	"char_mighto_gate5",
	"char_sanjo_base",
	"char_yujo_base",
	"char_narotu_sage",
	"char_olmaito_mode",
	"char_deko_full",
	"char_goju_base",
	"char_vegitto_base",
	"char_barbalva_base",
	"char_aizo_base",
	"char_brolli_legend",
	"char_madaro_base",
	"char_ichiro_mugetsu",
	"char_mighto_gate8",
	"char_vegitto_blue",
	"char_infernus_base",
	"char_iskander_base",
	"char_kizaro_base",
	"char_lanseiro_mode",
	"char_samurai_afro_base",
	"char_goko_dark_rose",
	"char_yoruka_shunko",
	"char_seiba_alter",
	"char_toshiru_bankai",
}
-- END LAUNCH CATALOG

-- Registro do catálogo de lançamento
for _, character in launchGenerated do
	assert(byId[character.Id] == nil, "personagem repetido: " .. character.Id)
	byId[character.Id] = character
end
local launchList: { Character } = {}
for _, id in LAUNCH_ORDER do
	local character = byId[id]
	assert(character and character.Launch, "personagem de lançamento sem entrada: " .. id)
	table.insert(launchList, character)
end

local f2pList: { Character } = {}
local premiumList: { Character } = {}
for _, character in launchList do
	if character.LaunchPool == "Premium" then
		table.insert(premiumList, character)
	else
		assert(character.LaunchPool == "F2P", "LaunchPool inválido: " .. character.Id)
		table.insert(f2pList, character)
	end
end

--[[
	RENDA BASE por Dice × Raridade — FONTE ÚNICA do BaseIncome de TODO personagem F2P (o
	catálogo gerado e os pilotos não trazem renda própria). O servidor (Formulas), a venda
	(SaleCore), o custo de nível, a fusão e o simulador leem o BaseIncome resultante.
	Auditoria e calibração: DICE_INCOME_AUDIT.md (python3 tools/sim/run_dice_income_audit.py).

	    BaseIncome = Anchor[raridade] × Growth ^ (ordem do Dice − pivô da raridade)
	    pivô = 1ª ordem + Pivot × (última ordem − 1ª ordem)   (faixa de Dice da raridade)

	• Anchor = renda aprovada da raridade (Comum 1 … Secreto 1200), valendo perto do 1º Dice em
	  que ela existe (Pivot = 0,10: o 1º Mítico do Spirit fica em 149 em vez de 160, o 1º
	  Lendário do Flame em 54) — o começo do jogo fica praticamente igual.
	• Growth = valor econômico de UM passo na progressão de Dice — a mesma taxa para todos os
	  Dice e raridades (nenhum multiplicador escolhido à mão por Dice). Mítico Spirit < Arcane <
	  Shadow < ... < Forbidden; um Lendário de Dice bem mais avançado passa um Mítico antigo.
	• "1ª ordem" vem do próprio roster (o Dice de menor ordem com personagem daquela raridade).
	• Arredondamento: 1 casa abaixo de 10, inteiro abaixo de 1000, 2 algarismos acima; sempre
	  estritamente crescente dentro da raridade.
	Personagens Premium e legados mantêm a renda própria (fora dos Dice F2P).
	Variante e Nível continuam multiplicando depois (Formulas:unitIncome).
	NÃO mexe em pesos, pity, Luck nem em quais personagens estão em cada Dice.
]]
local IncomeCurve = {
	Anchor = {
		Common = 1,
		Uncommon = 4,
		Rare = 9,
		Epic = 25,
		Legendary = 60,
		Mythic = 160,
		Divine = 425,
		Secret = 1200,
	} :: { [string]: number },
	Growth = 1.11,
	-- Ponto da faixa de Dice da raridade onde a renda = Anchor (0 = no 1º Dice; 0,5 = no meio).
	-- Calibração (DICE_INCOME_AUDIT.md): 1,11 / 0,10 deixa o Casual idêntico (±3%), os Dice
	-- iniciais e o 1º Rebirth em ±6% e é o mínimo para um Lendário tardio passar o Mítico antigo.
	Pivot = 0.1,
	-- Ordem oficial dos 16 Dice F2P (CatalogKey = DefaultDice). Conferida contra o DiceConfig
	-- em tests/DiceIncome.spec.luau (os configs não importam uns aos outros).
	DiceOrder = {
		"starter", "lucky", "rampart", "shinobi", "flame", "blade", "fighter", "storm",
		"spirit", "arcane", "shadow", "void", "colossus", "awakened", "celestial", "forbidden",
	},
	OrderOf = {} :: { [string]: number },
	FirstOrder = {} :: { [string]: number },
	Table = {} :: { [string]: { [number]: number } },
}
for order, key in IncomeCurve.DiceOrder do
	IncomeCurve.OrderOf[key] = order
end
for _, character in f2pList do
	local order = IncomeCurve.OrderOf[character.DefaultDice or ""]
	assert(order, "F2P sem Dice conhecido: " .. character.Id)
	local first = IncomeCurve.FirstOrder[character.Rarity]
	if first == nil or order < first then
		IncomeCurve.FirstOrder[character.Rarity] = order
	end
end
local function nice(x: number): number
	if x < 10 then
		return math.floor(x * 10 + 0.5) / 10
	elseif x < 1000 then
		return math.floor(x + 0.5)
	end
	local magnitude = 10 ^ (math.floor(math.log10(x)) - 1)
	return math.floor(x / magnitude + 0.5) * magnitude
end
IncomeCurve.LastOrder = {} :: { [string]: number }
for _, character in f2pList do
	local order = IncomeCurve.OrderOf[character.DefaultDice or ""]
	IncomeCurve.LastOrder[character.Rarity] = math.max(IncomeCurve.LastOrder[character.Rarity] or 0, order)
end
for rarity, first in IncomeCurve.FirstOrder do
	local row, last = {}, 0
	local pivot = first + IncomeCurve.Pivot * (IncomeCurve.LastOrder[rarity] - first)
	for order = first, #IncomeCurve.DiceOrder do
		local v = nice(IncomeCurve.Anchor[rarity] * IncomeCurve.Growth ^ (order - pivot))
		if v <= last then
			v = nice(last * 1.02 + 0.1)
		end
		row[order] = v
		last = v
	end
	IncomeCurve.Table[rarity] = row
end
-- BaseIncome de (raridade, Dice) — Dice pelo CatalogKey ("spirit"); nil fora dos Dice
local function baseIncomeFor(rarity: string, dice: string?): number?
	local order = IncomeCurve.OrderOf[dice or ""]
	local row = IncomeCurve.Table[rarity]
	return if order and row then row[order] else nil
end
;(IncomeCurve :: any).baseIncome = baseIncomeFor
for _, character in f2pList do
	local income = baseIncomeFor(character.Rarity, character.DefaultDice)
	assert(income and income > 0, "renda Dice×Raridade ausente: " .. character.Id)
	character.BaseIncome = income
end

return {
	List = f2pList, -- coleção principal (112 F2P): roll por Dice e progresso do Índice
	IncomeCurve = IncomeCurve, -- renda base Dice × Raridade (fonte única do BaseIncome F2P)
	ById = byId, -- todos (lançamento + legados)
	Count = #f2pList,
	Premium = premiumList, -- 9 Premium (progresso separado; fora dos Dice F2P)
	PremiumCount = #premiumList,
	Pilots = pilots, -- 10 pilotos do pipeline (fazem parte do lançamento)
	Launch = launchList, -- 121 de lançamento (F2P + Premium)
	Legacy = list, -- 24 lutadores do protótipo (fora do roll e do Índice)
}
