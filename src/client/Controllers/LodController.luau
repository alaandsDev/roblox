--!strict
--[[
	LodController: nível de detalhe simples das estações (10 bases x 8 personagens = 80+).
	Um loop central a cada 0.5 s (nada por personagem/por frame):
	    perto  (< NEAR)  -> modelo + aura + billboard completo
	    médio  (< FAR)   -> modelo + billboard reduzido (só renda)
	    longe            -> sem partículas/luz de aura (o BillboardGui já some pelo MaxDistance)
	"Efeitos reduzidos" desliga as auras sempre (e os VFX próprios dos personagens: atributo VFXTier).
	Bases com vários andares (FloorLegibility): letreiros de OUTRO andar não poluem o andar do
	jogador — andar vizinho só mostra a renda; 2+ andares de distância, nada; placas (preço/MÁX) e
	custos dos pads só no andar do jogador.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Players = game:GetService("Players")

local AuraConfig = require(ReplicatedStorage.Shared.Config.AuraConfig)
local BaseConfig = require(ReplicatedStorage.Shared.Config.BaseConfig)
local FloorLegibility = require(ReplicatedStorage.Shared.Modules.FloorLegibility)

local DataController = require(script.Parent.DataController)

local LodController = {}

local NEAR = 40
-- auras (V2) continuam ligadas até a distância normal de jogo da base (antes: 75 studs)
local FAR = AuraConfig.Budget.CullDistance
local LEGIBILITY = { FloorHeight = BaseConfig.FloorHeight, Tolerance = BaseConfig.FloorLegibility.Tolerance, IncomeMaxGap = BaseConfig.FloorLegibility.IncomeMaxGap }

local function setEnabled(parent: Instance?, name: string, on: boolean)
	local gui = parent and parent:FindFirstChild(name, true)
	if gui and gui:IsA("BillboardGui") then
		gui.Enabled = on
	end
end

-- altura dos pés do jogador local (nil = sem personagem: não esconde nada)
local function feetY(): number?
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hip = if humanoid then humanoid.HipHeight else 2
	return root.CFrame.Position.Y - root.Size.Y / 2 - hip
end

local function apply(station: Instance, distance: number, reduced: boolean, feet: number?)
	local level = if distance < NEAR then 1 elseif distance < FAR then 2 else 3
	local gap = FloorLegibility.gap(feet, station:GetAttribute("FloorY") :: number?, LEGIBILITY)
	if station:GetAttribute("Lod") == level and station:GetAttribute("LodReduced") == reduced and station:GetAttribute("LodFloorGap") == gap then
		return
	end
	local auraChanged = station:GetAttribute("Lod") ~= level or station:GetAttribute("LodReduced") ~= reduced
	station:SetAttribute("Lod", level)
	station:SetAttribute("LodReduced", reduced)
	station:SetAttribute("LodFloorGap", gap)
	local view = FloorLegibility.view(level, gap, LEGIBILITY)
	local anchor = station:FindFirstChild("InfoAnchor")
	local info = anchor and anchor:FindFirstChild("Info")
	local detail = info and info:FindFirstChild("Detail")
	if detail and detail:IsA("GuiObject") then
		detail.Visible = view.detail
	end
	if info and info:IsA("BillboardGui") then
		info.Enabled = view.income
	end
	setEnabled(station, "PlateGui", view.plate)
	setEnabled(station, "Cost", view.plate)
	if not auraChanged then
		return
	end
	local auraOn = level < 3 and not reduced
	for _, obj in station:GetDescendants() do
		if obj:IsA("ParticleEmitter") and obj.Name == "Aura" then
			obj.Enabled = auraOn
		elseif obj:IsA("PointLight") and obj.Name == "AuraLight" then
			obj.Enabled = auraOn
		elseif obj:GetAttribute("VFXTier") ~= nil and (obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Light")) then
			-- VFX próprio do personagem (pipeline de assets) e brilho de variante: mesma regra da aura
			(obj :: any).Enabled = auraOn
		end
	end
end

-- (testes) aplica a regra a uma estação
LodController._apply = apply

function LodController.Start()
	task.spawn(function()
		while true do
			task.wait(0.5)
			local camera = Workspace.CurrentCamera
			local bases = Workspace:FindFirstChild("Bases")
			if camera and bases then
				local settings = DataController.Get("Settings") or {}
				local reduced = settings.ReducedEffects == true
				local origin = camera.CFrame.Position
				local feet = feetY()
				for _, base in bases:GetChildren() do
					local runtime = base:FindFirstChild("RuntimeCharacters")
					if runtime then
						for _, station in runtime:GetChildren() do
							local anchor = station:FindFirstChild("InfoAnchor")
							if anchor and anchor:IsA("BasePart") then
								apply(station, (anchor.CFrame.Position - origin).Magnitude, reduced, feet)
							end
						end
					end
				end
			end
		end
	end)
end

return LodController
