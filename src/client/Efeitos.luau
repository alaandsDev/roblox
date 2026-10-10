-- Sons e efeitos visuais. Usa ReplicatedStorage.Modelos.Sons/<Nome> e Modelos.Efeitos/<Nome>
-- quando existem (baixados com tools/BuscarExtras.lua); sem eles, faz um efeito simples.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local Efeitos = {}

-- Cor do efeito simples quando não há um efeito baixado
local CORES = {
	Parede = ColorSequence.new(Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 120, 30)),
	Compra = ColorSequence.new(Color3.fromRGB(120, 255, 120), Color3.fromRGB(60, 200, 255)),
	Rebirth = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 255)),
	}),
	Nivel = ColorSequence.new(Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 255, 255)),
	Ovo = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 230, 120)),
}

local function pasta(nome: string): Instance?
	local modelos = ReplicatedStorage:FindFirstChild("Modelos")
	return modelos and modelos:FindFirstChild(nome)
end

local function acharSom(nome: string): Sound?
	local sons = pasta("Sons")
	local item = sons and sons:FindFirstChild(nome)
	if not item then
		return nil
	end
	if item:IsA("Sound") then
		return item
	end
	return item:FindFirstChildWhichIsA("Sound", true)
end

local ultimoSom: { [string]: number } = {}

function Efeitos.tocar(nome: string)
	local original = acharSom(nome)
	if not original then
		return
	end
	-- Evita empilhar o mesmo som (ex.: autoclick muito rápido)
	local agora = os.clock()
	if agora - (ultimoSom[nome] or 0) < 0.06 then
		return
	end
	ultimoSom[nome] = agora

	local som = original:Clone()
	som.Looped = false
	som.Parent = SoundService
	som:Play()
	som.Ended:Once(function()
		som:Destroy()
	end)
	task.delay(10, function()
		if som.Parent then
			som:Destroy()
		end
	end)
end

local function posicaoJogador(): Vector3?
	local character = player.Character
	local raiz = character and character:FindFirstChild("HumanoidRootPart")
	return if raiz and raiz:IsA("BasePart") then raiz.Position else nil
end

function Efeitos.explosao(tipo: string, posicao: Vector3?)
	local onde = posicao or posicaoJogador()
	if not onde then
		return
	end
	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.Transparency = 1
	ancora.Size = Vector3.one
	ancora.Position = onde
	ancora.Parent = workspace

	local efeitos = pasta("Efeitos")
	local modelo = efeitos and efeitos:FindFirstChild(tipo)
	local emissores = {}
	if modelo then
		for _, obj in modelo:GetDescendants() do
			if obj:IsA("ParticleEmitter") then
				local copia = obj:Clone()
				copia.Enabled = false
				copia.Parent = ancora
				table.insert(emissores, copia)
			end
		end
	end
	if #emissores == 0 then
		local simples = Instance.new("ParticleEmitter")
		simples.Color = CORES[tipo] or CORES.Compra
		simples.LightEmission = 0.8
		simples.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
		simples.Lifetime = NumberRange.new(0.6, 1.2)
		simples.Speed = NumberRange.new(10, 20)
		simples.SpreadAngle = Vector2.new(180, 180)
		simples.Acceleration = Vector3.new(0, -20, 0)
		simples.Enabled = false
		simples.Parent = ancora
		table.insert(emissores, simples)
	end
	for _, emissor in emissores do
		emissor:Emit(40)
	end
	task.delay(4, ancora.Destroy, ancora)
end

-- Eventos -----------------------------------------------------------------------------

remotes:WaitForChild("Efeito").OnClientEvent:Connect(function(tipo: string, posicao: Vector3?)
	Efeitos.tocar(tipo)
	Efeitos.explosao(tipo, posicao)
end)

remotes:WaitForChild("OvoAberto").OnClientEvent:Connect(function()
	Efeitos.tocar("Ovo")
end)

local nivelAnterior = player:GetAttribute("Nivel")
player:GetAttributeChangedSignal("Nivel"):Connect(function()
	local nivel = player:GetAttribute("Nivel")
	if nivelAnterior and nivel and nivel > nivelAnterior then
		Efeitos.tocar("Nivel")
		Efeitos.explosao("Nivel")
	end
	nivelAnterior = nivel
end)

-- Música de fundo em loop
task.spawn(function()
	local original = acharSom("Musica")
	if original then
		local musica = original:Clone()
		musica.Looped = true
		musica.Volume = math.min(musica.Volume, 0.3)
		musica.Parent = SoundService
		musica:Play()
	end
end)

return Efeitos
