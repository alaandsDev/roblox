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
