--!strict
--[[
	Valida a estrutura do mapa (puro, testável fora do Roblox).
	Recebe um "retrato" do mapa em tabelas simples (o MapService monta esse retrato a partir
	das Instances) e devolve a lista de problemas, com mensagens específicas.

	Retrato esperado:
	{
		points = { HubSpawn = true, ShopSpawn = true, TowerEntrance = true },
		bases = {
			{ name = "Base01", baseId = 1, hasPlayerSpawn = true, hasOwnerSign = true,
			  hasMoneyCollector = true, hasUpgradeArea = true, hasRuntimeCharacters = true,
			  floors = {
				{ name = "Floor01", floorId = 1, sides = {
					A = { { name = "Slot01", slotId = 1, side = "A", index = 1, floorId = 1 }, ... },
					B = { ... } } },
			  } },
		},
	}
]]

local MapValidator = {}

function MapValidator.validate(snapshot: any, expectedBases: number, slotsPerSide: number): { string }
	local problems = {}
	local function add(message: string)
		table.insert(problems, message)
	end

	for _, point in { "HubSpawn", "ShopSpawn", "TowerEntrance" } do
		if not snapshot.points[point] then
			add(`ponto {point} não encontrado`)
		end
	end

	if #snapshot.bases ~= expectedBases then
		add(`esperadas {expectedBases} bases, encontradas {#snapshot.bases}`)
	end

	local baseIds = {}
	for _, base in snapshot.bases do
		local label = base.name or "?"
		if type(base.baseId) ~= "number" then
			add(`{label}: sem atributo BaseId`)
		elseif baseIds[base.baseId] then
			add(`{label}: BaseId {base.baseId} repetido (também em {baseIds[base.baseId]})`)
		else
			baseIds[base.baseId] = label
		end
		for _, part in { "PlayerSpawn", "OwnerSign", "MoneyCollector", "UpgradeArea", "RuntimeCharacters" } do
			if not base["has" .. part] then
				add(`{label}: falta {part}`)
			end
		end

		local floor1 = nil
		for _, floor in base.floors or {} do
			if floor.floorId == 1 then
				floor1 = floor
			end
		end
		if not floor1 then
			add(`{label}: falta Floor01`)
		end

		local slotIds = {}
		for _, floor in base.floors or {} do
			local floorLabel = `{label}/{floor.name}`
			for _, side in { "A", "B" } do
				local slots = floor.sides and floor.sides[side]
				if not slots then
					add(`{floorLabel}: falta Side{side}`)
					continue
				end
				if #slots ~= slotsPerSide then
					add(`{floorLabel}/Side{side}: esperados {slotsPerSide} slots, encontrados {#slots}`)
				end
				for _, slot in slots do
					local slotLabel = `{floorLabel}/Side{side}/{slot.name}`
					if slot.side ~= side then
						add(`{slotLabel}: atributo Side = {tostring(slot.side)}, esperado {side}`)
					end
					if slot.floorId ~= floor.floorId then
						add(`{slotLabel}: FloorId {tostring(slot.floorId)} diferente do andar`)
					end
					if type(slot.slotId) ~= "number" then
						add(`{slotLabel}: sem SlotId`)
					elseif slotIds[slot.slotId] then
						add(`{slotLabel}: SlotId {slot.slotId} repetido`)
					else
						slotIds[slot.slotId] = true
					end
				end
			end
		end
	end

	return problems
end

return MapValidator
