--!strict
--[[
	AmbientController: animações decorativas do mapa, só no cliente (zero custo no servidor).
	- Esteira: ripas e objetos (dados/cristais) andando pela pista, com um pool fixo de peças
	  movidas por um único workspace:BulkMoveTo por quadro.
	- Dado mágico do Hub: gira e flutua devagar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local MapConfig = require(Shared.Config.MapConfig)
local BaseConfig = require(Shared.Config.BaseConfig)
local MapLayout = require(Shared.Modules.MapLayout)

local AmbientController = {}

local ITEM_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 120, 150),
	Color3.fromRGB(120, 200, 255),
	Color3.fromRGB(255, 220, 90),
	Color3.fromRGB(170, 120, 255),
}

local function makePart(size: Vector3, color: Color3, material: Enum.Material, parent: Instance): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function startConveyor()
	local c = MapConfig.Conveyor
	local layout = MapLayout.new(MapConfig, BaseConfig)
	local path = layout:conveyorPath()
	local runtime = workspace:WaitForChild("Runtime", 30)
	local effects = runtime and runtime:WaitForChild("Effects", 30)
	if not effects then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "ConveyorLocal"
	folder.Parent = effects

	local parts: { BasePart } = {}
	local offsets: { number } = {}
	local heights: { number } = {}
	local spins: { number } = {}
	local beltTop = layout:conveyorTop()

	for i = 1, c.SlatCount do
		local slat = makePart(Vector3.new(c.BeltWidth - 1.2, 0.15, 0.7), Color3.fromRGB(95, 95, 115), Enum.Material.SmoothPlastic, folder)
		table.insert(parts, slat)
		table.insert(offsets, (i - 1) * path.length / c.SlatCount)
		table.insert(heights, beltTop + 0.08)
		table.insert(spins, 0)
	end
	for i = 1, c.ItemCount do
		local crystal = i % 3 == 0
		local item = makePart(
			if crystal then Vector3.new(1.4, 2.6, 1.4) else Vector3.one * 2.2,
			ITEM_COLORS[i % #ITEM_COLORS + 1],
			if crystal then Enum.Material.Neon else Enum.Material.SmoothPlastic,
			folder
		)
		table.insert(parts, item)
		table.insert(offsets, (i - 0.5) * path.length / c.ItemCount)
		table.insert(heights, beltTop + (if crystal then 1.5 else 1.15))
		table.insert(spins, if crystal then 1 else 0.3)
	end

	local cframes = table.create(#parts)
	local elapsed = 0
	RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		-- Mesmo sentido/velocidade do transporte físico (MapConfig.Conveyor; MapLayout.beltVelocity)
		local travelled = elapsed * c.Speed * c.Direction
		for i, offset in offsets do
			local x, z, dx, dz = MapLayout.pointAt(path, offset + travelled)
			local position = Vector3.new(x, heights[i], z)
			local fx, fz = MapLayout.conveyorFlow(c, dx, dz)
			local cf = CFrame.lookAt(position, position + Vector3.new(fx, 0, fz))
			if spins[i] > 0 then
				cf *= CFrame.Angles(0, elapsed * spins[i], 0)
			end
			cframes[i] = cf
		end
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

local function startDice()
	local map = workspace:WaitForChild("Map", 30)
	local hub = map and map:WaitForChild("Hub", 30)
	local dice = hub and hub:WaitForChild("MagicDice", 30) :: Model?
	if not dice then
		return
	end
	local h = MapConfig.Hub
	local origin = CFrame.new(h.Center.x, h.DiceHeight, h.Center.z)
	local tilt = CFrame.Angles(0.5, 0, 0.35)
	local elapsed = 0
	RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		local bob = math.sin(elapsed * 1.2) * h.DiceBobAmplitude
		local spin = math.rad(h.DiceSpinSpeed) * elapsed
		dice:PivotTo(origin * CFrame.new(0, bob, 0) * CFrame.Angles(0, spin, 0) * tilt)
	end)
end

function AmbientController.Start()
	task.spawn(startConveyor)
	task.spawn(startDice)
end

return AmbientController
