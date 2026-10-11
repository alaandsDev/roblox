--!strict
-- Carrega assets de ReplicatedStorage.Assets com segurança.
-- Tudo que vem de fora (Creator Store) passa por aqui: TODOS os scripts são removidos
-- (backdoors são comuns em modelos grátis), e as partes ficam sem colisão/física.
--
--   AssetLoader.clone("Sounds", "UIClick")  -> cópia limpa ou nil
--   AssetLoader.model("Characters", "FlameRookie", 6) -> Model com PrimaryPart, escalado

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetLoader = {}

local function root(): Instance?
	return ReplicatedStorage:FindFirstChild("Assets")
end

function AssetLoader.exists(category: string, id: string): boolean
	local assets = root()
	local folder = assets and assets:FindFirstChild(category)
	return folder ~= nil and folder:FindFirstChild(id) ~= nil
end

-- Remove scripts e deixa as partes "decorativas" (sem colisão, sem massa)
function AssetLoader.sanitize(instance: Instance)
	local all = instance:GetDescendants()
	table.insert(all, instance)
	for _, obj in all do
		if obj:IsA("LuaSourceContainer") then
			obj:Destroy()
		elseif obj:IsA("BasePart") then
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.Massless = true
		end
	end
end

-- Cópia limpa de ReplicatedStorage.Assets.<category>.<id>, ou nil se não existir
function AssetLoader.clone(category: string, id: string): Instance?
	local assets = root()
	local folder = assets and assets:FindFirstChild(category)
	local original = folder and folder:FindFirstChild(id)
	if not original then
		return nil
	end
	local copy = original:Clone()
	AssetLoader.sanitize(copy)
	return copy
end

-- Igual a clone, mas sempre devolve um Model com PrimaryPart (embrulha Parts soltas).
-- Se "size" for informado, escala para caber num cubo desse tamanho (studs).
function AssetLoader.model(category: string, id: string, size: number?): Model?
	local copy = AssetLoader.clone(category, id)
	if not copy then
		return nil
	end
	local model: Model
	if copy:IsA("Model") then
		model = copy
	else
		model = Instance.new("Model")
		model.Name = id
		copy.Parent = model
	end
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	if not model.PrimaryPart then
		model:Destroy()
		return nil
	end
	if size then
		local extents = model:GetExtentsSize()
		local largest = math.max(extents.X, extents.Y, extents.Z)
		if largest > 0 then
			model:ScaleTo(model:GetScale() * size / largest)
		end
	end
	return model
end

return AssetLoader
