-- Deixa atravessáveis (só para este jogador) as paredes que a armadura dele já consegue quebrar.
-- O servidor confere a armadura de novo antes de dar as vitórias.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local paredes = workspace:WaitForChild("Pista"):WaitForChild("Paredes")

local function atualizar()
	local armadura = player:GetAttribute("Armadura") or 0
	for _, parede in paredes:GetChildren() do
		if parede:IsA("BasePart") then
			local quebravel = armadura >= (parede:GetAttribute("Vida") or math.huge)
			parede.CanCollide = not quebravel
			parede.Transparency = if quebravel then 0.6 else 0
		end
	end
end

player:GetAttributeChangedSignal("Armadura"):Connect(atualizar)
paredes.ChildAdded:Connect(atualizar)
atualizar()
