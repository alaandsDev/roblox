--!strict
-- Funções curtas para criar peças do mapa com padrões seguros:
-- sempre Anchored, sem física, e decoração sem colisão/consulta.

local CollectionService = game:GetService("CollectionService")

local Build = {}

export type Props = { [string]: any }

function Build.rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

function Build.theme(list: { number }): Color3
	return Color3.fromRGB(list[1], list[2], list[3])
end

local function apply(instance: Instance, props: Props?)
	if props then
		for key, value in props do
			if key ~= "Parent" then
				(instance :: any)[key] = value
			end
		end
		if props.Parent then
			instance.Parent = props.Parent
		end
	end
end

-- Peça sólida (colide). Use Build.decor para tirar colisão de enfeites.
function Build.part(size: Vector3, cframe: CFrame, props: Props?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	part.Size = size
	part.CFrame = cframe
	apply(part, props)
	return part
end

function Build.wedge(size: Vector3, cframe: CFrame, props: Props?): WedgePart
	local part = Instance.new("WedgePart")
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.Size = size
	part.CFrame = cframe
	apply(part, props)
	return part
end

-- Cilindro em pé: diameter x height, base apoiada em `bottom` (CFrame do centro da base)
function Build.cylinder(diameter: number, height: number, bottom: CFrame, props: Props?): Part
	local part = Build.part(
		Vector3.new(height, diameter, diameter),
		bottom * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		props
	)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function Build.ball(diameter: number, cframe: CFrame, props: Props?): Part
	local part = Build.part(Vector3.one * diameter, cframe, props)
	part.Shape = Enum.PartType.Ball
	return part
end

-- Enfeite: sem colisão, sem toque, invisível para raycasts
function Build.decor<T>(part: T): T
	local p = part :: any
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	return part
end

function Build.folder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function Build.model(name: string, parent: Instance?): Model
	local model = Instance.new("Model")
	model.Name = name
	if parent then
		model.Parent = parent
	end
	return model
end

function Build.tag(instance: Instance, ...: string)
	for _, tag in { ... } do
		CollectionService:AddTag(instance, tag)
	end
end

-- Texto numa face de uma peça (placas). lines = { { text, size (0-1 da altura), color? } }
function Build.sign(part: BasePart, face: Enum.NormalId, lines: { { any } }, background: Color3?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.MaxDistance = 260
	gui.Parent = part

	-- Com fundo, o texto vai dentro de um Frame colorido; sem fundo, direto na SurfaceGui
	local container: Instance = gui
	if background then
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = background
		frame.Parent = gui
		container = frame
	end

	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	for order, line in lines do
		local label = Instance.new("TextLabel")
		label.LayoutOrder = order
		label.Size = UDim2.fromScale(0.94, line[2])
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = line[1]
		label.TextColor3 = line[3] or Color3.new(1, 1, 1)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(30, 25, 45)
		stroke.Parent = label
		label.Parent = container
	end
	return gui
end

-- Painel de RANKING: título + `rows` linhas fixas Row1..RowN, cada uma com 3 colunas
-- (Rank | PlayerName | Value). Tamanho de texto FIXO por coluna (não TextScaled: nome longo é
-- truncado com "…" em vez de encolher a linha), valor alinhado à direita. O LeaderboardService
-- só troca os textos (nenhum objeto é criado a cada atualização).
Build.RankingRowColumns = { Rank = 0.14, PlayerName = 0.58, Value = 0.24 }
function Build.rankingBoard(part: BasePart, face: Enum.NormalId, title: string, titleColor: Color3, rows: number): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.MaxDistance = 260
	gui.Parent = part

	local layout = Instance.new("UIListLayout")
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.02, 0)
	layout.Parent = gui

	local function label(parent: Instance, name: string, text: string, width: number, align: Enum.TextXAlignment, size: number, color: Color3?): TextLabel
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(width, 1)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = false
		l.TextSize = size
		l.TextXAlignment = align
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Text = text
		l.TextColor3 = color or Color3.new(1, 1, 1)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(30, 25, 45)
		stroke.Parent = l
		l.Parent = parent
		return l
	end

	local titleLabel = label(gui, "Title", title, 0.94, Enum.TextXAlignment.Center, 30, titleColor)
	titleLabel.Size = UDim2.fromScale(0.94, 0.14)
	titleLabel.LayoutOrder = 0
	-- 5 linhas: 0,12 cada (como sempre); mais linhas (Magnata top 10) dividem o espaço
	local rowHeight = math.min(0.12, 0.78 / rows)
	local textSize = math.floor(24 * math.min(1, rowHeight / 0.1))
	for i = 1, rows do
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.LayoutOrder = i
		row.BackgroundTransparency = if i % 2 == 0 then 1 else 0.82
		row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		row.BorderSizePixel = 0
		row.Size = UDim2.fromScale(0.94, rowHeight)
		row.Parent = gui
		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Padding = UDim.new(0.02, 0)
		rowLayout.Parent = row
		local columns = Build.RankingRowColumns
		label(row, "Rank", i .. ".", columns.Rank, Enum.TextXAlignment.Right, textSize).LayoutOrder = 1
		label(row, "PlayerName", "—", columns.PlayerName, Enum.TextXAlignment.Left, textSize).LayoutOrder = 2
		label(row, "Value", "", columns.Value, Enum.TextXAlignment.Right, textSize, Color3.fromRGB(255, 220, 80)).LayoutOrder = 3
	end
	return gui
end

-- Prompt "Abrir" para áreas que ainda não funcionam (o MapService responde "em breve")
function Build.prompt(parent: Instance, interactId: string, objectText: string, actionText: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Interact"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("InteractId", interactId)
	prompt.Parent = parent
	return prompt
end

return Build
