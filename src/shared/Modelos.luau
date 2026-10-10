-- Usa os modelos que você colocar em ReplicatedStorage.Modelos (ex.: itens grátis da Store).
-- Estrutura: Modelos/Pets/<Id>, Modelos/Ovos/<Id>, Modelos/Escudos/<Id>.
-- O nome do modelo precisa ser igual ao Id usado no Config.luau.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modelos = {}

-- Retorna uma cópia pronta para uso (sem scripts, sem colisão) ou nil se não existir
function Modelos.clonar(categoria: string, id: string): Model?
	local pasta = ReplicatedStorage:FindFirstChild("Modelos")
	local subpasta = pasta and pasta:FindFirstChild(categoria)
	local original = subpasta and subpasta:FindFirstChild(id)
	if not original then
		return nil
	end

	local copia = original:Clone()
	local modelo: Model
	if copia:IsA("Model") then
		modelo = copia
	elseif copia:IsA("BasePart") then
		modelo = Instance.new("Model")
		modelo.Name = id
		copia.Parent = modelo
	else
		copia:Destroy()
		return nil
	end

	local partes = {}
	for _, obj in modelo:GetDescendants() do
		-- Modelos grátis às vezes trazem scripts maliciosos (backdoors): removemos todos
		if obj:IsA("LuaSourceContainer") then
			obj:Destroy()
		elseif obj:IsA("BasePart") then
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.Massless = true
			table.insert(partes, obj)
		end
	end
	if #partes == 0 then
		modelo:Destroy()
		return nil
	end
	if not modelo.PrimaryPart then
		modelo.PrimaryPart = partes[1]
	end
	return modelo
end

-- Escala o modelo para caber num cubo de "tamanho" studs
function Modelos.ajustarTamanho(modelo: Model, tamanho: number)
	local maior = math.max(modelo:GetExtentsSize().X, modelo:GetExtentsSize().Y, modelo:GetExtentsSize().Z)
	if maior > 0 then
		modelo:ScaleTo(modelo:GetScale() * tamanho / maior)
	end
end

-- Solda todas as partes na PrimaryPart (para modelos que se movem presos a algo)
function Modelos.soldar(modelo: Model)
	for _, obj in modelo:GetDescendants() do
		if obj:IsA("BasePart") then
			obj.Anchored = false
			if obj ~= modelo.PrimaryPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = modelo.PrimaryPart
				weld.Part1 = obj
				weld.Parent = obj
			end
		end
	end
end

return Modelos
