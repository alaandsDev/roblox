--!strict
--[[
	WORLD ART PASS: linguagem blocky (Roblox clássico / LEGO) aplicada ao mundo inteiro DEPOIS de
	construído, sem mudar posição/tamanho/colisão de nada (layout e gameplay intocados).

	Hierarquia por PAPEL (atributo "ArtRole" na peça vence; senão a heurística abaixo decide):
	  Baseplate  grama/piso grande            -> Plastic + STUDS no topo (muita leitura de studs)
	  Path       caminhos/ladrilhos            -> Plastic liso (peça), sem studs no meio
	  Trim       meio-fio, bordas, tampos      -> Plastic + studs (borda montada peça por peça)
	  Structure  paredes, pilares, vigas       -> Plastic + studs no topo + inlet embaixo (bloco)
	  Special    Neon/vidro/efeitos            -> intocado (acabamento próprio)
	  Nature     folhas/troncos/pedras/flores  -> material mantido (anime/cartoon), cor viva
	  Skip       esteira, personagens, pads    -> intocado
	Cores: saturação +15% (cinza/branco ficam como estão) — vida sem depender de Bloom.
	SurfaceType.Studs/Inlet é recurso nativo do Roblox: zero textura, zero peça extra (mobile).
]]

local WorldStyle = {}

local SKIP_ANCESTORS = { Conveyor = true, RuntimeCharacters = true, Runtime = true, Effects = true }
local NATURE_NAMES = { Leaves = true, Leaf = true, Trunk = true, Root = true, Rock = true, Coconuts = true, Petal = true, Flower = true, Stem = true }
local GROUND_HINT = { "Grass", "Island", "Lawn", "Ground", "Baseplate", "Platform", "Landing", "Plaza", "Floor" }
local PATH_HINT = { "Path", "Tile", "Slab", "Road", "Walk", "Crossing", "Carpet" }
local TRIM_HINT = { "Curb", "Edge", "Trim", "Border", "Cap", "Rim", "Frame", "Step" }

local function hasHint(name: string, list: { string }): boolean
	for _, hint in list do
		if string.find(name, hint, 1, true) then
			return true
		end
	end
	return false
end

local function skipped(part: BasePart): boolean
	local node: Instance? = part.Parent
	while node and node ~= workspace do
		if SKIP_ANCESTORS[node.Name] or node:GetAttribute("ArtSkip") == true or node:GetAttribute("Station") == true then
			return true
		end
		node = node.Parent
	end
	return false
end

-- Papel da peça (ArtRole explícito vence)
function WorldStyle.role(part: BasePart): string
	local explicit = part:GetAttribute("ArtRole")
	if type(explicit) == "string" then
		return explicit
	end
	if part:GetAttribute("ArtSkip") == true or skipped(part) then
		return "Skip"
	end
	local material = part.Material
	if material == Enum.Material.Neon or material == Enum.Material.Glass or material == Enum.Material.ForceField or part.Transparency > 0.4 then
		return "Special"
	end
	local name = part.Name
	local parent = part.Parent
	local parentName = if parent then parent.Name else ""
	if NATURE_NAMES[name] or string.find(parentName, "Tree", 1, true) or string.find(parentName, "Palm", 1, true)
		or string.find(parentName, "Bush", 1, true) or string.find(parentName, "Rocks", 1, true) or string.find(parentName, "Flower", 1, true)
	then
		return "Nature"
	end
	if material == Enum.Material.Water or material == Enum.Material.Sand then
		return "Nature"
	end
	local size = part.Size
	local flat = size.Y <= 3 and size.X >= 10 and size.Z >= 10
	if hasHint(name, TRIM_HINT) then
		return "Trim"
	end
	if hasHint(name, PATH_HINT) or (parent and parent:FindFirstAncestor("Paths") ~= nil and flat) or parentName == "Paths" then
		return "Path"
	end
	if material == Enum.Material.Grass or (flat and hasHint(name, GROUND_HINT)) then
		return "Baseplate"
	end
	if material == Enum.Material.SmoothPlastic or material == Enum.Material.Plastic then
		return "Structure"
	end
	return "Nature" -- madeira/pedra/tecido etc.: mantém o material, só a cor fica viva
end

-- Saturação +15% (cores neutras não mudam)
function WorldStyle.vivid(color: Color3): Color3
	local h, s, v = color:ToHSV()
	if s < 0.08 then
		return color
	end
	return Color3.fromHSV(h, math.min(1, s * 1.15 + 0.02), math.min(1, v * 1.03))
end

export type Stats = { [string]: number }

-- Aplica o estilo em `root` (pasta do mapa ou base). Idempotente (marca "ArtStyled").
function WorldStyle.apply(root: Instance): Stats
	local stats: Stats = { Baseplate = 0, Path = 0, Trim = 0, Structure = 0, Nature = 0, Special = 0, Skip = 0, Studded = 0 }
	for _, obj in root:GetDescendants() do
		if obj:IsA("BasePart") and not obj:IsA("Terrain") and obj:GetAttribute("ArtStyled") ~= true then
			local part = obj :: BasePart
			local role = WorldStyle.role(part)
			stats[role] = (stats[role] or 0) + 1
			if role ~= "Skip" and role ~= "Special" then
				part.Color = WorldStyle.vivid(part.Color)
			end
			if role == "Baseplate" or role == "Trim" or role == "Structure" then
				part.Material = Enum.Material.Plastic
				part.TopSurface = Enum.SurfaceType.Studs
				stats.Studded += 1
				if role == "Structure" then
					part.BottomSurface = Enum.SurfaceType.Inlet
				end
			elseif role == "Path" then
				part.Material = Enum.Material.Plastic
				part.TopSurface = Enum.SurfaceType.Smooth
			end
			part:SetAttribute("ArtStyled", true)
		end
	end
	return stats
end

return WorldStyle
