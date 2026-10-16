--!strict
--[[
	HUB LANDMARKS — ART PASS: cada sistema reconhecível pela SILHUETA (cor só ajuda).
	Tudo com Parts (in-house, blocky, studs pelo WorldStyle), poucos props GRANDES.

	    MERCADO     toldo listrado + balcão + produtos grandes + SACOLA de compras flutuando
	    VENDER      MÁQUINA: funil de entrada -> esteira -> processador com visor $ -> rampa de moedas
	    TROCAS      dois balcões SIMÉTRICOS (azul | laranja) frente a frente + arco com ↔ gigante
	    MISSÕES     QUADRO de tarefas (cartões com pinos, ✓ e ★) + "!" sobre o NPC guia
	    FUSÃO       3 ENTRADAS (cristais) -> NÚCLEO (orbe) -> 1 SAÍDA (gema): 3 -> 1
	    MELHORIAS   3 pilares crescentes com SETAS ↑ + engrenagem
	    RENASCER    anel-portal com setas CIRCULARES girando + estrela no centro

	Animação: NADA de script nas estruturas. Peças animadas recebem a tag "HubDeco" e atributos
	(DecoMode = Spin | Bob | Pulse | Slide | Tumble, DecoSpeed, DecoAmp, DecoPhase, DecoAxis, DecoWave,
	DecoHz = atualizações/s);
	efeitos (ParticleEmitter/Beam) recebem "HubDecoFx". O HubDecorationController (cliente) anima
	tudo num único loop, com LOD por distância. Animado = sempre sem colisão.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapConfig = require(ReplicatedStorage.Shared.Config.MapConfig)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Build = require(script.Parent.Build)
local Decor = require(script.Parent.Decor)

local Landmarks = {}

local rgb = Build.rgb
local color = Build.theme
local P = MapConfig.Visual.Palette

Landmarks.DecoTag = "HubDeco"
Landmarks.FxTag = "HubDecoFx"

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

-- marca uma peça/modelo como animado (cliente) e garante que não colide
function Landmarks.animate(inst: Instance, mode: string, props: { [string]: any }?)
	inst:SetAttribute("DecoMode", mode)
	local list: { [string]: any } = props or {}
	for k, v in list do
		inst:SetAttribute("Deco" .. k, v)
	end
	if inst:IsA("BasePart") then
		Build.decor(inst)
	else
		for _, d in inst:GetDescendants() do
			if d:IsA("BasePart") then
				Build.decor(d)
			end
		end
	end
	Build.tag(inst, Landmarks.DecoTag)
end

local function fx(inst: Instance, baseRate: number?)
	if baseRate then
		inst:SetAttribute("BaseRate", baseRate)
	end
	Build.tag(inst, Landmarks.FxTag)
end

-- seta (haste + ponta) apontando para +Y local de `cf`
local function arrow(parent: Instance, name: string, cf: CFrame, length: number, width: number, arrowColor: Color3): Model
	local model = Build.model(name, parent)
	Build.decor(Build.part(Vector3.new(width, length * 0.6, width), cf * CFrame.new(0, length * 0.3, 0), { Name = "Shaft", Color = arrowColor, Material = Enum.Material.Neon, Parent = model }))
	Build.decor(Build.wedge(Vector3.new(width, length * 0.4, width * 1.4), cf * CFrame.new(0, length * 0.8, width * 0.35), { Name = "HeadA", Color = arrowColor, Material = Enum.Material.Neon, Parent = model }))
	Build.decor(Build.wedge(Vector3.new(width, length * 0.4, width * 1.4), cf * CFrame.new(0, length * 0.8, -width * 0.35) * CFrame.Angles(0, math.pi, 0), { Name = "HeadB", Color = arrowColor, Material = Enum.Material.Neon, Parent = model }))
	model.PrimaryPart = model:FindFirstChild("Shaft") :: BasePart
	return model
end

local function coin(parent: Instance, name: string, cf: CFrame, diameter: number, symbol: boolean?): Part
	local c = Build.part(Vector3.new(diameter * 0.16, diameter, diameter), cf, { Name = name, Color = color(P.Gold), Parent = parent })
	c.Shape = Enum.PartType.Cylinder
	Build.decor(c)
	if symbol then
		Build.sign(c, Enum.NormalId.Left, { { "$", 0.9, rgb(255, 250, 220) } })
		Build.sign(c, Enum.NormalId.Right, { { "$", 0.9, rgb(255, 250, 220) } })
	end
	return c
end

------------------------------------------------------------------------------------
-- MERCADO: barraca comercial de verdade (toldo + balcão + produtos) e SACOLA flutuando

function Landmarks.market(model: Model, origin: CFrame, w: number, d: number): BasePart
	local orange, cream = rgb(255, 150, 60), rgb(255, 250, 240)
	Build.part(Vector3.new(w, 1, d), origin * CFrame.new(0, 0.5, 0), { Name = "Floor", Color = color(P.Wood), Material = Enum.Material.WoodPlanks, Parent = model })
	Build.part(Vector3.new(w, 8, 1.2), origin * CFrame.new(0, 5, d / 2 - 0.6), { Name = "BackWall", Color = color(P.WoodDark), Material = Enum.Material.WoodPlanks, Parent = model })
	for _, x in { -w / 2 + 0.9, w / 2 - 0.9 } do
		for _, z in { -d / 2 + 0.9, d / 2 - 0.9 } do
			Build.part(Vector3.new(1.8, 10, 1.8), origin * CFrame.new(x, 6, z), { Name = "Post", Color = color(P.WoodDark), Material = Enum.Material.Wood, Parent = model })
		end
	end
	-- TOLDO listrado inclinado + franja recortada na frente (silhueta de feira)
	local stripes = 6
	for i = 1, stripes do
		local x = -w / 2 + (i - 0.5) * w / stripes
		local stripe = if i % 2 == 0 then cream else orange
		Build.decor(Build.part(Vector3.new(w / stripes + 0.05, 0.6, d + 3), origin * CFrame.new(x, 11.4, -1) * CFrame.Angles(math.rad(12), 0, 0), { Name = "Awning", Color = stripe, Parent = model }))
		Build.decor(Build.wedge(Vector3.new(w / stripes - 0.2, 1.4, 0.5), origin * CFrame.new(x, 9.8, -d / 2 - 2.3) * CFrame.Angles(0, 0, math.pi), { Name = "AwningFringe", Color = stripe, Parent = model }))
	end
	-- BALCÃO com faixa frontal
	local counter = Build.part(Vector3.new(w - 4, 3.5, 2.4), origin * CFrame.new(0, 2.75, -d / 2 + 2.2), { Name = "Counter", Color = rgb(150, 100, 60), Material = Enum.Material.Wood, Parent = model })
	Build.decor(Build.part(Vector3.new(w - 3.6, 1, 0.3), origin * CFrame.new(0, 3.6, -d / 2 + 0.9), { Name = "CounterStripe", Color = orange, Parent = model }))
	-- PRODUTOS grandes no balcão: caixote de frutas, saco, pilha de moedas
	local top = 4.5
	Build.decor(Build.part(Vector3.new(2.6, 1.6, 1.8), origin * CFrame.new(-4.2, top + 0.8, -d / 2 + 2.2), { Name = "ProduceCrate", Color = color(P.Wood), Material = Enum.Material.WoodPlanks, Parent = model }))
	Build.decor(Build.part(Vector3.new(2.2, 0.8, 1.4), origin * CFrame.new(-4.2, top + 1.9, -d / 2 + 2.2), { Name = "Produce", Color = rgb(255, 80, 80), Parent = model }))
	Build.decor(Build.part(Vector3.new(2, 2.6, 2), origin * CFrame.new(0, top + 1.3, -d / 2 + 2.2) * CFrame.Angles(0, 0.4, 0), { Name = "Sack", Color = rgb(215, 180, 120), Material = Enum.Material.Fabric, Parent = model }))
	Build.decor(Build.part(Vector3.new(0.8, 0.5, 0.8), origin * CFrame.new(0, top + 2.85, -d / 2 + 2.2), { Name = "SackTie", Color = rgb(150, 60, 40), Parent = model }))
	for k = 0, 2 do
		Build.decor(Build.cylinder(1.9, 0.5, origin * CFrame.new(4.2, top + k * 0.5, -d / 2 + 2.2), { Name = "CoinStack", Color = color(P.Gold), Parent = model }))
	end
	-- prateleiras na parede do fundo com caixas/potes grandes
	for row, y in { 4.2, 7 } do
		Build.decor(Build.part(Vector3.new(w - 3, 0.4, 1.6), origin * CFrame.new(0, y, d / 2 - 2), { Name = "Shelf", Color = color(P.WoodDark), Parent = model }))
		for i, x in { -5, 0, 5 } do
			local tint = ({ rgb(120, 220, 90), rgb(255, 210, 70), rgb(110, 170, 255) })[(i + row) % 3 + 1]
			Build.decor(Build.part(Vector3.new(2.2, 1.8, 1.2), origin * CFrame.new(x, y + 1.1, d / 2 - 2), { Name = "ShelfBox", Color = tint, Parent = model }))
		end
	end
	-- caixotes nas laterais (poucos e grandes)
	for i, offset in { Vector3.new(-w / 2 - 2, 1.5, -d / 2 + 2), Vector3.new(w / 2 + 2, 1.5, -d / 2 + 3), Vector3.new(w / 2 + 2, 4.1, -d / 2 + 3) } do
		Build.decor(Build.part(Vector3.new(3, 2.6, 3), origin * CFrame.new(offset) * CFrame.Angles(0, i * 0.2, 0), { Name = "Crate", Color = color(P.Wood), Material = Enum.Material.WoodPlanks, Parent = model }))
	end
	-- ÍCONE: sacola de compras gigante flutuando e girando sobre o balcão
	local bag = Build.model("FloatingBag", model)
	local bagCf = origin * CFrame.new(0, 8.6, -d / 2 + 1.5)
	Build.part(Vector3.new(3.2, 3.4, 1.6), bagCf, { Name = "BagBody", Color = orange, Parent = bag })
	Build.part(Vector3.new(3.4, 0.5, 1.8), bagCf * CFrame.new(0, 1.6, 0), { Name = "BagRim", Color = cream, Parent = bag })
	Build.part(Vector3.new(0.35, 1.4, 0.35), bagCf * CFrame.new(-0.8, 2.4, 0), { Name = "HandleL", Color = cream, Parent = bag })
	Build.part(Vector3.new(0.35, 1.4, 0.35), bagCf * CFrame.new(0.8, 2.4, 0), { Name = "HandleR", Color = cream, Parent = bag })
	Build.part(Vector3.new(1.95, 0.35, 0.35), bagCf * CFrame.new(0, 3.1, 0), { Name = "HandleTop", Color = cream, Parent = bag })
	bag.PrimaryPart = bag:FindFirstChild("BagBody") :: BasePart
	Landmarks.animate(bag, "Spin", { Speed = 45, Amp = 0.5, Hz = 15 })
	return counter
end

------------------------------------------------------------------------------------
-- VENDER: MÁQUINA/processador — entrada -> esteira -> processador ($) -> moedas saindo

function Landmarks.sell(model: Model, origin: CFrame, w: number, d: number): BasePart
	local green, gold, metal = rgb(80, 200, 110), color(P.Gold), rgb(150, 160, 180)
	Build.part(Vector3.new(w, 1, d), origin * CFrame.new(0, 0.5, 0), { Name = "Floor", Color = color(P.StoneDark), Material = Enum.Material.Slate, Parent = model })
	-- PROCESSADOR (bloco central grande) com visor $
	local machine = Build.part(Vector3.new(8, 8, 6), origin * CFrame.new(0, 5, 2.5), { Name = "SellMachine", Color = green, Parent = model })
	Build.part(Vector3.new(9, 1.2, 7), origin * CFrame.new(0, 9.6, 2.5), { Name = "MachineCap", Color = metal, Parent = model })
	local screen = Build.decor(Build.part(Vector3.new(5.4, 3.4, 0.3), origin * CFrame.new(0, 6, -0.6), { Name = "MachineScreen", Color = rgb(40, 255, 140), Material = Enum.Material.Neon, Parent = model }))
	Build.sign(screen, Enum.NormalId.Front, { { "$", 0.95, rgb(20, 70, 40) } })
	Landmarks.animate(screen, "Pulse", { Speed = 2.2, Amp = 0.35, Hz = 10 })
	-- chaminés com luz
	for _, x in { -2.6, 2.6 } do
		Build.decor(Build.cylinder(1.4, 3, origin * CFrame.new(x, 10.2, 3.5), { Name = "Stack", Color = metal, Parent = model }))
		Build.decor(Build.cylinder(1.6, 0.5, origin * CFrame.new(x, 13.2, 3.5), { Name = "StackTop", Color = rgb(255, 220, 80), Material = Enum.Material.Neon, Parent = model }))
	end
	-- ENTRADA: funil (esquerda) + mini esteira até o processador
	local hopperX = -w / 2 + 2.6
	Build.part(Vector3.new(3.6, 4, 3.6), origin * CFrame.new(hopperX, 3, 1), { Name = "HopperBase", Color = metal, Parent = model })
	Build.decor(Build.wedge(Vector3.new(4.8, 2.2, 2), origin * CFrame.new(hopperX, 6.1, 0.2) * CFrame.Angles(0, math.pi, 0), { Name = "HopperFunnel", Color = green, Parent = model }))
	Build.decor(Build.wedge(Vector3.new(4.8, 2.2, 2), origin * CFrame.new(hopperX, 6.1, 1.8), { Name = "HopperFunnel", Color = green, Parent = model }))
	local beltY = 5.2
	local belt = Build.decor(Build.part(Vector3.new(3.4, 0.4, 2.2), origin * CFrame.new(-4.7, beltY, 1), { Name = "InputBelt", Color = rgb(55, 55, 70), Parent = model }))
	for i = 0, 2 do
		Build.decor(Build.part(Vector3.new(0.3, 0.42, 2.2), origin * CFrame.new(-6 + i * 1.2, beltY + 0.02, 1), { Name = "BeltStripe", Color = rgb(255, 200, 60), Parent = model }))
	end
	-- item (bloco de personagem) entrando na máquina: desliza pela esteira e recomeça
	local item = Build.part(Vector3.new(1.1, 1.1, 1.1), origin * CFrame.new(-6.2, beltY + 0.75, 1), { Name = "SellItem", Color = rgb(170, 110, 255), Parent = model })
	Landmarks.animate(item, "Slide", { Speed = 0.6, Amp = 2.6, Axis = "X", Wave = "Saw", Hz = 20 })
	local _ = belt
	-- SAÍDA: rampa de moedas (direita) + bandeja com pilha
	local chuteX = w / 2 - 2.6
	Build.decor(Build.wedge(Vector3.new(3, 3, 4), origin * CFrame.new(chuteX, 2.5, -0.5) * CFrame.Angles(0, math.pi, 0), { Name = "OutputChute", Color = metal, Parent = model }))
	Build.part(Vector3.new(4, 1, 3.6), origin * CFrame.new(chuteX, 1.5, -3.6), { Name = "CoinTray", Color = green, Parent = model })
	for k = 0, 1 do
		Build.decor(Build.cylinder(2.2, 0.6, origin * CFrame.new(chuteX, 2 + k * 0.6, -3.6), { Name = "CoinStack", Color = gold, Parent = model }))
	end
	-- moedas saindo de tempos em tempos (1 emissor barato, só no cliente perto: LOD)
	local outlet = Build.decor(Build.part(Vector3.new(1, 1, 1), origin * CFrame.new(chuteX, 4.4, 0.6), { Name = "CoinOutlet", Transparency = 1, Parent = model }))
	local coins = Instance.new("ParticleEmitter")
	coins.Name = "SellCoins"
	coins.Texture = SPARK
	coins.Color = ColorSequence.new(rgb(255, 215, 70))
	coins.LightEmission = 0.6
	coins.Size = NumberSequence.new(0.9, 0.5)
	coins.Lifetime = NumberRange.new(0.9, 1.2)
	coins.Speed = NumberRange.new(4, 6)
	coins.SpreadAngle = Vector2.new(15, 15)
	coins.Acceleration = Vector3.new(0, -18, 0)
	coins.EmissionDirection = Enum.NormalId.Top
	coins.Rate = 2.5
	coins.Parent = outlet
	fx(coins, 2.5)
	-- MOEDA gigante no topo (girando devagar)
	local big = coin(model, "BigCoin", origin * CFrame.new(0, 15.6, 2.5) * CFrame.Angles(0, math.rad(90), 0), 6.5, true)
	Landmarks.animate(big, "Spin", { Speed = 30, Hz = 12 })
	-- balcão (prompt) na frente
	local counter = Build.part(Vector3.new(6, 3.2, 2), origin * CFrame.new(0, 2.6, -d / 2 + 1.6), { Name = "Counter", Color = green, Parent = model })
	return counter
end

------------------------------------------------------------------------------------
-- TROCAS: estação social SIMÉTRICA — jogador A (azul) ↔ jogador B (laranja)

function Landmarks.trade(model: Model, o: CFrame): BasePart
	local blue, orange, white = rgb(70, 150, 255), rgb(255, 140, 50), rgb(255, 250, 240)
	Build.part(Vector3.new(8, 0.2, 12), o * CFrame.new(-4, 0.1, 0), { Name = "RugA", Color = blue, Material = Enum.Material.Fabric, Parent = model })
	Build.part(Vector3.new(8, 0.2, 12), o * CFrame.new(4, 0.1, 0), { Name = "RugB", Color = orange, Material = Enum.Material.Fabric, Parent = model })
	-- dois balcões frente a frente, cada um com uma moldura de "slot" e um item girando
	for i, side in { -1, 1 } do
		local tint = if side < 0 then blue else orange
		local booth = Build.model(if side < 0 then "TradeBoothA" else "TradeBoothB", model)
		local bx = side * 5.2
		Build.part(Vector3.new(3, 3.2, 4), o * CFrame.new(bx, 1.6, 0), { Name = "Booth", Color = tint, Parent = booth })
		Build.decor(Build.part(Vector3.new(3.4, 0.4, 4.4), o * CFrame.new(bx, 3.4, 0), { Name = "BoothTop", Color = white, Parent = booth }))
		-- moldura do slot (quadrado em pé, virado para o centro) — POLISH: maior e mais grossa
		local slot = o * CFrame.new(bx, 5.9, 0) * CFrame.Angles(0, side * math.pi / 2, 0)
		for _, e in { { 0, 1.85, 4.3, 0.6 }, { 0, -1.85, 4.3, 0.6 }, { 1.85, 0, 0.6, 4.3 }, { -1.85, 0, 0.6, 4.3 } } do
			Build.decor(Build.part(Vector3.new(e[3], e[4], 0.5), slot * CFrame.new(e[1], e[2], 0), { Name = "SlotFrame", Color = tint, Material = Enum.Material.Neon, Parent = booth }))
		end
		-- fundo escuro do slot: o item e a moldura colorida destacam de longe
		Build.decor(Build.part(Vector3.new(3.2, 3.2, 0.2), slot * CFrame.new(0, 0, 0.3), { Name = "SlotBack", Color = rgb(35, 35, 55), Parent = booth }))
		local cube = Build.part(Vector3.new(1.8, 1.8, 1.8), slot, { Name = "SlotItem", Color = if side < 0 then rgb(255, 230, 90) else rgb(170, 110, 255), Parent = booth })
		Landmarks.animate(cube, "Tumble", { Speed = 40 + i * 10, Hz = 12 })
	end
	-- ARCO central com ↔ gigante (a silhueta "um lado <-> outro lado")
	-- (postes por DENTRO da área: o caminho da base passa ao lado)
	-- POLISH: postes e arco um pouco mais altos (o ↔ sobe), cada poste com a COR do seu lado
	for i, x in { -6.6, 6.6 } do
		Build.part(Vector3.new(1.4, 13.4, 1.4), o * CFrame.new(x, 6.7, 4.6), { Name = "ArchPost", Color = color(P.WoodDark), Parent = model })
		Build.decor(Build.part(Vector3.new(0.3, 7, 2.2), o * CFrame.new(x - math.sign(x) * 0.85, 7.5, 4.6), { Name = "SideBanner", Color = if i == 1 then blue else orange, Parent = model }))
	end
	local beam = Build.part(Vector3.new(14.6, 2.6, 1.6), o * CFrame.new(0, 14.6, 4.6), { Name = "ArchBeam", Color = rgb(230, 80, 80), Parent = model })
	Build.decor(beam)
	Build.sign(beam, Enum.NormalId.Front, { { "🤝 " .. Localization.t("map.trade"), 0.85 } })
	-- painel atrás do ↔: metade AZUL | metade LARANJA (os dois lados lidos de longe)
	local arrowY = 10.3
	Build.decor(Build.part(Vector3.new(5.9, 3.6, 0.4), o * CFrame.new(-2.95, arrowY, 5.4), { Name = "ArrowPanelA", Color = rgb(30, 60, 120), Parent = model }))
	Build.decor(Build.part(Vector3.new(5.9, 3.6, 0.4), o * CFrame.new(2.95, arrowY, 5.4), { Name = "ArrowPanelB", Color = rgb(130, 60, 20), Parent = model }))
	-- ↔ MAIOR: duas setas horizontais (respiram em direções opostas)
	local left = arrow(model, "TradeArrowL", o * CFrame.new(-0.3, arrowY, 4.6) * CFrame.Angles(0, 0, math.pi / 2), 5.4, 1.4, blue)
	local right = arrow(model, "TradeArrowR", o * CFrame.new(0.3, arrowY, 4.6) * CFrame.Angles(0, 0, -math.pi / 2), 5.4, 1.4, orange)
	Landmarks.animate(left, "Slide", { Speed = 1.4, Amp = 0.45, Axis = "Y", Hz = 15 })
	Landmarks.animate(right, "Slide", { Speed = 1.4, Amp = 0.45, Axis = "Y", Phase = math.pi, Hz = 15 })
	-- mesa central (onde a troca "acontece": prompt)
	local tableTop = Build.part(Vector3.new(3, 0.5, 3), o * CFrame.new(0, 3, -1), { Name = "Table", Color = rgb(170, 120, 75), Material = Enum.Material.Wood, Parent = model })
	Build.part(Vector3.new(1, 2.7, 1), o * CFrame.new(0, 1.35, -1), { Name = "TableLeg", Color = rgb(140, 95, 60), Parent = model })
	return tableTop
end

------------------------------------------------------------------------------------
-- MISSÕES: QUADRO DE TAREFAS (cartões presos, ✓, ★, recompensa) + "!" sobre o NPC

function Landmarks.missions(model: Model, mo: CFrame): BasePart
	local wood, cork, paper = color(P.WoodDark), rgb(190, 135, 80), rgb(250, 244, 225)
	for _, x in { -7, 7 } do
		Build.part(Vector3.new(1.2, 11, 1.2), mo * CFrame.new(x, 5.5, 2.4), { Name = "Post", Color = wood, Material = Enum.Material.Wood, Parent = model })
	end
	local board = Build.part(Vector3.new(13, 8, 0.8), mo * CFrame.new(0, 5.8, 2.2), { Name = "Board", Color = cork, Material = Enum.Material.Wood, Parent = model })
	Decor.chunkyBorder(model, mo * CFrame.new(0, 5.8, 1.7) * CFrame.Angles(math.pi / 2, 0, 0), 13.6, 8.6, 0.6, 0.6, rgb(120, 75, 40))
	-- cabeçalho com o título (placa física integrada, sobre o quadro)
	local header = Build.part(Vector3.new(10, 2.2, 0.8), mo * CFrame.new(0, 11, 2.2), { Name = "Header", Color = rgb(230, 150, 40), Parent = model })
	Build.decor(header)
	Build.sign(header, Enum.NormalId.Front, { { "📜 " .. Localization.t("map.missions"), 0.85, rgb(60, 30, 10) } })
	for _, side in { -1, 1 } do
		Build.decor(Build.wedge(Vector3.new(16, 2, 4), mo * CFrame.new(0, 13.2, 2.4 + side * 2) * CFrame.Angles(0, if side == 1 then math.pi else 0, 0), { Name = "Roof", Color = rgb(200, 90, 50), Parent = model }))
	end
	-- 4 CARTÕES (levemente tortos) com pino; 2 com ✓, 1 com ★, 1 com moeda
	type Card = { x: number, y: number, tilt: number, icon: string }
	local cards: { Card } = {
		{ x = -4.4, y = 7.2, tilt = -0.08, icon = "check" },
		{ x = -1.4, y = 4.4, tilt = 0.06, icon = "star" },
		{ x = 1.8, y = 7.3, tilt = 0.1, icon = "check" },
		{ x = 4.6, y = 4.5, tilt = -0.07, icon = "coin" },
	}
	for i, c in cards do
		local cf = mo * CFrame.new(c.x, c.y, 1.65) * CFrame.Angles(0, 0, c.tilt)
		Build.decor(Build.part(Vector3.new(2.6, 3, 0.15), cf, { Name = "QuestCard", Color = paper, Parent = model }))
		Build.decor(Build.ball(0.5, cf * CFrame.new(0, 1.3, -0.15), { Name = "Pin", Color = rgb(230, 60, 60), Parent = model }))
		for line = 0, 1 do
			Build.decor(Build.part(Vector3.new(1.8, 0.18, 0.05), cf * CFrame.new(0, 0.55 - line * 0.45, -0.1), { Name = "TextLine", Color = rgb(150, 140, 125), Parent = model }))
		end
		local icon = cf * CFrame.new(0, -0.7, -0.12)
		if c.icon == "check" then
			Build.decor(Build.part(Vector3.new(0.3, 0.6, 0.08), icon * CFrame.new(-0.25, -0.05, 0) * CFrame.Angles(0, 0, math.rad(40)), { Name = "Check", Color = rgb(60, 210, 90), Material = Enum.Material.Neon, Parent = model }))
			Build.decor(Build.part(Vector3.new(0.3, 1.1, 0.08), icon * CFrame.new(0.2, 0.15, 0) * CFrame.Angles(0, 0, math.rad(-35)), { Name = "Check", Color = rgb(60, 210, 90), Material = Enum.Material.Neon, Parent = model }))
		elseif c.icon == "star" then
			local star = Build.model("QuestStar", model)
			Build.part(Vector3.new(0.9, 0.9, 0.08), icon, { Name = "StarA", Color = rgb(255, 215, 50), Material = Enum.Material.Neon, Parent = star })
			Build.part(Vector3.new(0.9, 0.9, 0.08), icon * CFrame.Angles(0, 0, math.rad(45)), { Name = "StarB", Color = rgb(255, 215, 50), Material = Enum.Material.Neon, Parent = star })
			Landmarks.animate(star, "Pulse", { Speed = 2.6, Amp = 0.5, Hz = 10 })
		else
			coin(model, "RewardCoin", icon * CFrame.Angles(0, math.rad(90), 0), 0.9)
		end
		local _ = i
	end
	-- NPC guia (original, blocky) + "!" de missão flutuando sobre ele
	local npc = Build.model("GuideNPC", model)
	local npcBase = mo * CFrame.new(-9.5, 0, 0)
	Build.part(Vector3.new(2, 2, 1), npcBase * CFrame.new(0, 3, 0), { Name = "Torso", Color = rgb(60, 120, 220), Parent = npc })
	Build.part(Vector3.new(2, 2, 1), npcBase * CFrame.new(0, 1, 0), { Name = "Legs", Color = rgb(50, 50, 70), Parent = npc })
	Build.part(Vector3.new(1.6, 1.6, 1.6), npcBase * CFrame.new(0, 4.8, 0), { Name = "Head", Color = rgb(255, 210, 170), Parent = npc })
	Build.decor(Build.part(Vector3.new(2.4, 0.5, 2.4), npcBase * CFrame.new(0, 5.8, 0), { Name = "Hat", Color = rgb(255, 200, 60), Parent = npc }))
	-- NPC é cenário: sem colisão (ninguém tropeça nele)
	for _, part in npc:GetChildren() do
		Build.decor(part)
	end
	local mark = Build.model("QuestMark", model)
	Build.part(Vector3.new(0.7, 1.8, 0.7), npcBase * CFrame.new(0, 8.4, 0), { Name = "MarkBar", Color = rgb(255, 220, 50), Material = Enum.Material.Neon, Parent = mark })
	Build.part(Vector3.new(0.7, 0.7, 0.7), npcBase * CFrame.new(0, 7, 0), { Name = "MarkDot", Color = rgb(255, 220, 50), Material = Enum.Material.Neon, Parent = mark })
	Landmarks.animate(mark, "Bob", { Speed = 2, Amp = 0.4, Hz = 15 })
	return board
end

------------------------------------------------------------------------------------
-- FUSÃO: 3 ENTRADAS -> NÚCLEO -> 1 SAÍDA (energia convergindo por 3 beams)

function Landmarks.fusion(model: Model, fo: CFrame): BasePart
	-- POLISH de luz: o NÚCLEO é o ponto mais brilhante; entradas, runa, anel e resultado
	-- enquadram (tons mais escuros, menos neon/bloom) em vez de estourar a imagem
	local teal = rgb(120, 255, 220)
	local tealDim = rgb(55, 150, 135)
	Build.part(Vector3.new(18, 1, 18), fo * CFrame.new(0, 0.5, 0), { Name = "Platform", Color = rgb(70, 60, 110), Material = Enum.Material.Slate, Parent = model })
	Build.part(Vector3.new(12, 1, 12), fo * CFrame.new(0, 1.5, 0), { Name = "Platform2", Color = rgb(96, 82, 148), Material = Enum.Material.Slate, Parent = model })
	local rune = Decor.chunkyBorder(model, fo * CFrame.new(0, 2, 0), 9, 9, 0.5, 0.12, tealDim)
	for _, part in rune:GetChildren() do
		(part :: BasePart).Material = Enum.Material.Neon
	end
	-- NÚCLEO: altar + orbe pulsando
	local altar = Build.part(Vector3.new(4.6, 3.5, 4.6), fo * CFrame.new(0, 3.75, 0), { Name = "Altar", Color = rgb(110, 90, 170), Material = Enum.Material.Slate, Parent = model })
	Decor.crystal(model, fo * CFrame.new(0, 5.5, 0), 4, tealDim)
	local core = Build.ball(4, fo * CFrame.new(0, 10.6, 0), { Name = "FusionCore", Color = teal, Material = Enum.Material.Neon, Parent = model })
	Landmarks.animate(core, "Pulse", { Speed = 2.4, Amp = 0.25, Hz = 12 })
	-- anel do núcleo: sem neon branco (era o maior "estouro"); só contorno escuro girando
	local shell = Build.part(Vector3.new(6, 0.4, 6), fo * CFrame.new(0, 10.6, 0) * CFrame.Angles(0, 0, math.rad(25)), { Name = "CoreRing", Color = rgb(60, 70, 110), Parent = model })
	shell:SetAttribute("ArtRole", "Special")
	Landmarks.animate(shell, "Spin", { Speed = 50, Hz = 15 })
	local coreAtt = Instance.new("Attachment")
	coreAtt.Name = "CoreIn"
	coreAtt.Parent = core
	-- 3 ENTRADAS atrás (pedestal + cristal), cada uma ligada ao núcleo por 1 beam
	type Input = { x: number, z: number, tint: Color3 }
	local inputs: { Input } = {
		{ x = -5.6, z = 4.6, tint = rgb(120, 70, 165) },
		{ x = 0, z = 6.6, tint = rgb(60, 105, 165) },
		{ x = 5.6, z = 4.6, tint = rgb(160, 70, 120) },
	}
	for i, info in inputs do
		local base = fo * CFrame.new(info.x, 2, info.z)
		local pedestal = Build.part(Vector3.new(2.6, 2.2, 2.6), base * CFrame.new(0, 1.1, 0), { Name = "FusionInput", Color = color(P.StoneDark), Parent = model })
		Decor.crystal(model, base * CFrame.new(0, 2.2, 0), 3.6, info.tint)
		local from = Instance.new("Attachment")
		from.Name = "InputTop"
		from.Position = Vector3.new(0, 3.4, 0)
		from.Parent = pedestal
		local energy = Instance.new("Beam")
		energy.Name = "FusionEnergy" .. i
		energy.Attachment0 = from
		energy.Attachment1 = coreAtt
		energy.Color = ColorSequence.new(info.tint, teal)
		-- mais fino e mais transparente na saída da entrada; mais forte chegando no núcleo
		energy.Width0 = 0.4
		energy.Width1 = 0.3
		energy.FaceCamera = true
		energy.LightEmission = 0.45
		energy.Texture = SPARK
		energy.TextureSpeed = 1.6
		energy.TextureLength = 2
		energy.Transparency = NumberSequence.new(0.55, 0.15)
		energy.CurveSize0 = 1.5
		energy.Segments = 10
		energy.Parent = pedestal
		fx(energy)
	end
	-- 1 SAÍDA na frente: pedestal + gema dourada girando (o resultado)
	local out = fo * CFrame.new(0, 2, -6.4)
	Build.part(Vector3.new(3, 1.6, 3), out * CFrame.new(0, 0.8, 0), { Name = "FusionOutput", Color = rgb(255, 205, 60), Parent = model })
	-- resultado: dourado SÓLIDO (sem neon): lê como prêmio sem competir com o núcleo
	local gem = Build.part(Vector3.new(2, 2, 2), out * CFrame.new(0, 3.2, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), { Name = "ResultGem", Color = rgb(235, 180, 40), Parent = model })
	gem:SetAttribute("ArtRole", "Special")
	Landmarks.animate(gem, "Spin", { Speed = 60, Amp = 0.35, Hz = 15 })
	Decor.rockCluster(model, fo * CFrame.new(-10, 0, 8), 4, 901, false)
	Decor.rockCluster(model, fo * CFrame.new(10, 0, 8), 4, 902, false)
	Decor.sign(model, fo * CFrame.new(0, 0, 10.5), "✨ " .. Localization.t("map.fusion"), rgb(110, 70, 220), { width = 12, lift = 6 })
	return altar
end

------------------------------------------------------------------------------------
-- MELHORIAS: ↑ ↑↑ ↑↑↑ — três pilares crescentes com setas + engrenagem girando

function Landmarks.upgrades(model: Model, o: CFrame): BasePart
	local blue, cyan = rgb(70, 140, 255), rgb(90, 230, 255)
	Build.part(Vector3.new(16, 1, 14), o * CFrame.new(0, 0.5, 0), { Name = "Platform", Color = rgb(55, 70, 120), Material = Enum.Material.Slate, Parent = model })
	-- POLISH: CARCAÇA que une tudo numa estação — base única (pilares + console em cima),
	-- painel traseiro com moldura lateral, faixa de energia ligando os pilares e indicadores
	local deck = 2.4 -- topo da base da máquina
	local frameColor = rgb(40, 50, 90)
	Build.part(Vector3.new(14, deck - 1, 10.4), o * CFrame.new(0, 1 + (deck - 1) / 2, -0.3), { Name = "MachineBase", Color = rgb(75, 95, 170), Parent = model })
	Build.decor(Build.part(Vector3.new(14.4, 0.3, 10.8), o * CFrame.new(0, deck + 0.05, -0.3), { Name = "MachineTrim", Color = frameColor, Parent = model }))
	Build.part(Vector3.new(14, 6, 1), o * CFrame.new(0, deck + 3, 4.4), { Name = "MachineBackPanel", Color = frameColor, Parent = model })
	Build.decor(Build.part(Vector3.new(14.6, 0.6, 1.4), o * CFrame.new(0, deck + 6.2, 4.4), { Name = "MachineCap", Color = blue, Parent = model }))
	for _, x in { -7.3, 7.3 } do
		Build.part(Vector3.new(1, 7, 10.4), o * CFrame.new(x, deck + 3.5 - 0.5, -0.3), { Name = "MachineSide", Color = frameColor, Parent = model })
	end
	-- faixa de energia ligando os 3 pilares (lê como UM sistema) + 3 indicadores de nível
	Build.decor(Build.part(Vector3.new(12, 0.4, 0.3), o * CFrame.new(0, deck + 0.6, -0.15), { Name = "PowerStrip", Color = cyan, Material = Enum.Material.Neon, Parent = model }))
	for i = 1, 3 do
		Build.decor(Build.part(Vector3.new(0.8, 0.8 * i, 0.2), o * CFrame.new(-6 + i * 1.1, 1 + (deck - 1) / 2, -5.55), { Name = "LevelLight", Color = cyan, Material = Enum.Material.Neon, Parent = model }))
	end
	for i, h in { 3, 5.5, 8 } do
		local x = (i - 2) * 4.6
		Build.part(Vector3.new(3, h, 3), o * CFrame.new(x, deck + h / 2, 1.5), { Name = "UpgradePillar", Color = if i == 3 then blue else rgb(90, 110, 200), Parent = model })
		Build.decor(Build.part(Vector3.new(3.4, 0.5, 3.4), o * CFrame.new(x, deck + h + 0.25, 1.5), { Name = "PillarCap", Color = cyan, Material = Enum.Material.Neon, Parent = model }))
		local a = arrow(model, "UpgradeArrow" .. i, o * CFrame.new(x, deck + h + 1, 1.5), 2.4 + i * 0.6, 0.9, cyan)
		Landmarks.animate(a, "Bob", { Speed = 2.4, Amp = 0.5, Phase = i * 0.9, Hz = 15 })
	end
	-- engrenagem atrás (disco + 6 dentes), girando no próprio eixo
	local gear = Build.model("UpgradeGear", model)
	local gcf = o * CFrame.new(0, 10.6, 5.6) * CFrame.Angles(0, math.rad(90), 0)
	local disk = Build.part(Vector3.new(1, 7, 7), gcf, { Name = "GearDisk", Color = rgb(255, 205, 60), Parent = gear })
	disk.Shape = Enum.PartType.Cylinder
	for k = 1, 6 do
		local ang = k / 6 * math.pi * 2
		Build.part(Vector3.new(1, 1.8, 1.8), gcf * CFrame.Angles(ang, 0, 0) * CFrame.new(0, 3.8, 0), { Name = "GearTooth", Color = rgb(255, 205, 60), Parent = gear })
	end
	Build.part(Vector3.new(1.2, 2.4, 2.4), gcf, { Name = "GearHub", Color = blue, Parent = gear })
	gear.PrimaryPart = disk
	Landmarks.animate(gear, "Spin", { Speed = 25, Axis = "X", Hz = 12 })
	-- engrenagem montada no topo do painel traseiro (eixo saindo da carcaça)
	Build.decor(Build.part(Vector3.new(1, 1, 1.4), o * CFrame.new(0, 10.6, 4.9), { Name = "GearAxle", Color = frameColor, Parent = model }))
	-- console (prompt) EM CIMA da base, na frente
	local console = Build.part(Vector3.new(4, 2.6, 2), o * CFrame.new(0, deck + 1.3, -4.3), { Name = "Console", Color = frameColor, Parent = model })
	Build.decor(Build.part(Vector3.new(3.2, 1.4, 0.2), o * CFrame.new(0, deck + 1.6, -5.35), { Name = "ConsoleScreen", Color = cyan, Material = Enum.Material.Neon, Parent = model }))
	Decor.sign(model, o * CFrame.new(-7.2, 0, -5.8), "⬆️ " .. Localization.t("map.upgrades"), blue, { width = 9, lift = 4.5, height = 2.6 })
	return console
end

------------------------------------------------------------------------------------
-- RENASCER: anel-portal com SETAS CIRCULARES girando (ciclo) e estrela no centro

function Landmarks.rebirth(model: Model, o: CFrame): BasePart
	local magenta, gold = rgb(235, 70, 120), rgb(255, 210, 70)
	local platform = Build.cylinder(15, 1, o, { Name = "Platform", Color = rgb(90, 40, 80), Parent = model })
	local _ = platform
	-- anel estático (8 blocos) em pé, virado para o Hub
	local center = o * CFrame.new(0, 7.4, 1.5)
	for k = 1, 8 do
		local ang = k / 8 * math.pi * 2
		Build.part(Vector3.new(2.4, 1.8, 1.4), center * CFrame.Angles(0, 0, ang) * CFrame.new(0, 4.8, 0), { Name = "RebirthRing", Color = magenta, Parent = model })
	end
	-- POLISH: pés alinhados com os blocos de baixo do anel (antes ficavam soltos abaixo deles)
	local footX = math.sin(math.rad(45)) * 4.8
	local footTop = 7.4 - math.cos(math.rad(45)) * 4.8
	for _, x in { -footX, footX } do
		Build.part(Vector3.new(1.6, footTop - 1, 1.4), o * CFrame.new(x, 1 + (footTop - 1) / 2, 1.5), { Name = "RingFoot", Color = magenta, Parent = model })
	end
	-- disco escuro dentro do anel: o portal lê como portal de qualquer ângulo (sem VFX)
	local disc = Build.part(Vector3.new(0.2, 8, 8), center * CFrame.new(0, 0, 0.35) * CFrame.Angles(0, math.rad(90), 0), { Name = "PortalDisc", Color = rgb(45, 20, 60), Transparency = 0.15, Parent = model })
	disc.Shape = Enum.PartType.Cylinder
	disc:SetAttribute("ArtRole", "Special")
	Build.decor(disc)
	-- setas circulares (3 arcos com ponta) girando dentro do anel
	local arrows = Build.model("RebirthArrows", model)
	for k = 1, 3 do
		local base = center * CFrame.Angles(0, 0, k / 3 * math.pi * 2)
		Build.part(Vector3.new(2.8, 0.7, 0.6), base * CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(-12)), { Name = "ArcA", Color = gold, Material = Enum.Material.Neon, Parent = arrows })
		Build.part(Vector3.new(2.4, 0.7, 0.6), base * CFrame.Angles(0, 0, math.rad(-38)) * CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(-12)), { Name = "ArcB", Color = gold, Material = Enum.Material.Neon, Parent = arrows })
		Build.wedge(Vector3.new(0.6, 1.6, 1.3), base * CFrame.Angles(0, 0, math.rad(32)) * CFrame.new(0, 3.1, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)), { Name = "ArcHead", Color = gold, Material = Enum.Material.Neon, Parent = arrows })
	end
	local hub = Build.part(Vector3.new(0.4, 0.4, 0.4), center, { Name = "ArrowsPivot", Transparency = 1, Parent = arrows })
	arrows.PrimaryPart = hub
	Landmarks.animate(arrows, "Spin", { Speed = -35, Axis = "Z", Hz = 15 })
	-- estrela no centro (2 quadrados a 45°), pulsando
	local star = Build.model("RebirthStar", model)
	Build.part(Vector3.new(2.2, 2.2, 0.5), center, { Name = "StarA", Color = rgb(255, 245, 200), Material = Enum.Material.Neon, Parent = star })
	Build.part(Vector3.new(2.2, 2.2, 0.5), center * CFrame.Angles(0, 0, math.rad(45)), { Name = "StarB", Color = rgb(255, 245, 200), Material = Enum.Material.Neon, Parent = star })
	Landmarks.animate(star, "Pulse", { Speed = 2, Amp = 0.45, Hz = 10 })
	-- pedestal (prompt) na frente + placa
	local pedestal = Build.part(Vector3.new(3.6, 3, 3), o * CFrame.new(0, 2, -4.6), { Name = "RebirthPedestal", Color = rgb(150, 50, 100), Parent = model })
	Build.decor(Build.part(Vector3.new(2.6, 0.5, 2), o * CFrame.new(0, 3.75, -4.6), { Name = "PedestalGlow", Color = magenta, Material = Enum.Material.Neon, Parent = model }))
	Decor.sign(model, o * CFrame.new(7.2, 0, -5.8), "♻️ " .. Localization.t("map.rebirth"), magenta, { width = 9, lift = 4.5, height = 2.6 })
	return pedestal
end

------------------------------------------------------------------------------------
-- POLISH da LOJA DE DADOS (não redesenha): dados menores flutuando/girando + brilho suave

function Landmarks.diceShopPolish(model: Model, origin: CFrame, w: number, d: number, towerTop: number)
	-- 3 dados menores flutuando em volta do dado gigante (cada um gira devagar no próprio eixo)
	for i, info in { { -6.5, 4.2, 2.6 }, { 6.5, 5.6, 2.2 }, { 0, 9.6, 1.8 } } do
		local dice = Decor.smallDice(model, origin * CFrame.new(info[1], towerTop + 8 + info[2], -d / 2 + 4) * CFrame.Angles(0.5 * i, 0.3, 0.2), info[3])
		dice.Name = "FloatingDice"
		dice.PrimaryPart = dice:FindFirstChild("Body") :: BasePart
		Landmarks.animate(dice, "Tumble", { Speed = 25 + i * 8, Amp = 0.6, Phase = i, Hz = 10 })
	end
	-- brilho suave (1 emissor) no dado gigante
	local anchor = Build.decor(Build.part(Vector3.new(1, 1, 1), origin * CFrame.new(0, towerTop + 10, -d / 2 + 4), { Name = "DiceSparkle", Transparency = 1, Parent = model }))
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "DiceSparkles"
	sparkle.Texture = SPARK
	sparkle.Color = ColorSequence.new(rgb(255, 230, 255), rgb(200, 150, 255))
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(0.8, 0)
	sparkle.Lifetime = NumberRange.new(1, 1.6)
	sparkle.Speed = NumberRange.new(1, 2)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Rate = 4
	sparkle.Parent = anchor
	fx(sparkle, 4)
	local _ = w
end

------------------------------------------------------------------------------------
-- POLISH das TORRES: números dos andares, bandeiras e portal "respirando"

function Landmarks.towerPolish(parent: Instance, portal: BasePart, tiers: { BasePart })
	Landmarks.animate(portal, "Pulse", { Speed = 1.6, Amp = 0.18, Hz = 10 })
	for i, tier in tiers do
		Build.sign(tier, Enum.NormalId.Front, { { tostring(i), 0.55, rgb(255, 230, 120) } })
	end
	local top = tiers[#tiers]
	if top then
		local cf = top.CFrame * CFrame.new(0, top.Size.Y / 2, 0)
		for _, x in { -top.Size.X / 2 - 1.5, top.Size.X / 2 + 1.5 } do
			Decor.flag(parent, cf * CFrame.new(x, 0, 0), 9, rgb(255, 90, 140))
		end
	end
end

return Landmarks
