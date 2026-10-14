--!strict
--[[
	Design system do Roll Legends: TODA janela/botão usa estes tokens (evita cada tela parecer
	de um jogo diferente). Estilo "simulator moderno": fonte arredondada bold, contorno escuro,
	gradiente, sombra, cantos bem arredondados, botões grandes para toque.
]]

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

return {
	Font = Enum.Font.FredokaOne,
	FontBody = Enum.Font.GothamBold,

	CornerRadius = 14,
	CornerRadiusSmall = 10,
	StrokeThickness = 3,
	StrokeColor = rgb(25, 20, 40),
	TextStroke = 2.5,

	Spacing = 10,
	Padding = 14,
	HeaderHeight = 64,

	-- Tamanhos (em pixels "de referência" 1280x720; o UIScale da tela ajusta)
	ButtonSizes = {
		Nav = Vector2.new(150, 54),
		Side = Vector2.new(88, 92),
		Bottom = Vector2.new(104, 108),
		Roll = Vector2.new(140, 146),
		Small = Vector2.new(120, 44),
		Action = Vector2.new(190, 56),
		Close = Vector2.new(56, 56),
	},
	-- HUD icon-first: o chip ocupa só parte da área de toque (que continua grande no mobile)
	Hud = {
		ChipScale = 0.68,
		PrimaryChipScale = 0.84,
		ChipRoundness = 0.3,
		BadgeSize = 22,
	},
	PopupSizes = {
		Small = Vector2.new(520, 400),
		Medium = Vector2.new(760, 500),
		Large = Vector2.new(900, 560),
	},
	ReferenceResolution = Vector2.new(1280, 720),

	Colors = {
		PanelBackground = rgb(38, 36, 54),
		PanelInner = rgb(28, 27, 40),
		Card = rgb(52, 50, 72),
		CardHover = rgb(64, 62, 88),
		Dim = rgb(0, 0, 0),
		Text = rgb(255, 255, 255),
		TextMuted = rgb(185, 185, 205),
		Money = rgb(90, 245, 90),
		Gems = rgb(120, 220, 255),
		Luck = rgb(120, 255, 140),
		Danger = rgb(255, 70, 70),
		Warning = rgb(255, 205, 60),
		Success = rgb(70, 220, 90),
		Primary = rgb(80, 160, 255),
		Purple = rgb(160, 90, 245),
		Orange = rgb(255, 150, 50),
		HeaderRed = rgb(225, 45, 55),
		HeaderGold = rgb(255, 205, 120),
		Locked = rgb(70, 70, 85),
	},

	Shadow = { Offset = 4, Transparency = 0.55 },
	DimTransparency = 0.45,
	OpenScaleFrom = 0.9,
	OpenTime = 0.16,
}
