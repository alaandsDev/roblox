--!strict
--[[
	Roster inicial: 24 lutadores ORIGINAIS (arquétipos anime/fantasy, sem personagens licenciados).

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
	byId[character.Id] = character
end

return {
	List = list,
	ById = byId,
	Count = #list,
}
