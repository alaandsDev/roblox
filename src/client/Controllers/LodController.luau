--!strict
--[[
	LodController: nível de detalhe simples das estações (10 bases x 8 personagens = 80+).
	Um loop central a cada 0.5 s (nada por personagem/por frame):
	    perto  (< NEAR)  -> modelo + aura + billboard completo
	    médio  (< FAR)   -> modelo + billboard reduzido (só renda)
	    longe            -> sem partículas/luz de aura (o BillboardGui já some pelo MaxDistance)
	"Efeitos reduzidos" desliga as auras sempre.
]]

local Workspace = game:GetService("Workspace")

local DataController = require(script.Parent.DataController)

local LodController = {}

local NEAR = 45
local FAR = 90

local function apply(station: Instance, distance: number, reduced: boolean)
	local level = if distance < NEAR then 1 elseif distance < FAR then 2 else 3
	if station:GetAttribute("Lod") == level and station:GetAttribute("LodReduced") == reduced then
		return
	end
	station:SetAttribute("Lod", level)
	station:SetAttribute("LodReduced", reduced)
	local anchor = station:FindFirstChild("InfoAnchor")
	local info = anchor and anchor:FindFirstChild("Info")
	local detail = info and info:FindFirstChild("Detail")
	if detail and detail:IsA("GuiObject") then
		detail.Visible = level == 1
	end
	local auraOn = level < 3 and not reduced
	for _, obj in station:GetDescendants() do
		if obj:IsA("ParticleEmitter") and obj.Name == "Aura" then
			obj.Enabled = auraOn
		elseif obj:IsA("PointLight") and obj.Name == "AuraLight" then
			obj.Enabled = auraOn
		end
	end
end

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
				for _, base in bases:GetChildren() do
					local runtime = base:FindFirstChild("RuntimeCharacters")
					if runtime then
						for _, station in runtime:GetChildren() do
							local anchor = station:FindFirstChild("InfoAnchor")
							if anchor and anchor:IsA("BasePart") then
								apply(station, (anchor.CFrame.Position - origin).Magnitude, reduced)
							end
						end
					end
				end
			end
		end
	end)
end

return LodController
