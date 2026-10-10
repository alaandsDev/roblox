-- Deixa atravessáveis (só para este jogador) as paredes que a armadura dele já consegue quebrar.
-- O servidor confere a armadura de novo antes de dar as vitórias.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mundos = workspace:WaitForChild("Mundos")

local paredes: { BasePart } = {}

local function atualizar()
	local armadura = player:GetAttribute("Armadura") or 0
	for _, parede in paredes do
		local quebravel = armadura >= parede:GetAttribute("Vida")
		parede.CanCollide = not quebravel
		parede.Transparency = if quebravel then 0.6 else 0
	end
end

local function registrar(obj: Instance)
	if obj:IsA("BasePart") and obj:GetAttribute("Vida") then
		table.insert(paredes, obj)
		atualizar()
	end
end

for _, obj in mundos:GetDescendants() do
	registrar(obj)
end
mundos.DescendantAdded:Connect(registrar)
player:GetAttributeChangedSignal("Armadura"):Connect(atualizar)
atualizar()
