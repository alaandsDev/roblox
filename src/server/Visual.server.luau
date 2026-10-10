-- Deixa o mapa colorido e vivo: iluminação clara e saturação alta.
-- Você também pode ajustar isso à mão em Lighting no Studio (lá, coloque Technology = Future).
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

Lighting.ClockTime = 13
Lighting.Brightness = 3
Lighting.Ambient = Color3.fromRGB(110, 110, 120)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 0.5
Lighting.GlobalShadows = true

local cor = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
cor.Saturation = Config.Visual.Saturacao
cor.Contrast = Config.Visual.Contraste
cor.Brightness = Config.Visual.Brilho
cor.Parent = Lighting

local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Intensity = 0.4
bloom.Size = 24
bloom.Threshold = 1.5
bloom.Parent = Lighting

-- Céu: usa o primeiro Sky dentro de ReplicatedStorage.Modelos.Ceu (se você baixou um)
local modelos = ReplicatedStorage:FindFirstChild("Modelos")
local pastaCeu = modelos and modelos:FindFirstChild("Ceu")
local ceu = pastaCeu and pastaCeu:FindFirstChildWhichIsA("Sky", true)
if ceu then
	local antigo = Lighting:FindFirstChildOfClass("Sky")
	if antigo then
		antigo:Destroy()
	end
	ceu:Clone().Parent = Lighting
end
