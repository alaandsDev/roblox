--!strict
-- Funções utilitárias para tabelas. Módulo puro: não usa APIs do Roblox
-- (pode ser testado fora do Studio).

local TableUtil = {}

-- Cópia profunda (tabelas aninhadas também são copiadas). Não copia metatables.
function TableUtil.deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value :: any do
		copy[TableUtil.deepCopy(k)] = TableUtil.deepCopy(v)
	end
	return (copy :: any) :: T
end

function TableUtil.deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for k, v in a do
		if not TableUtil.deepEqual(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

function TableUtil.count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

--[[
	Garante que "data" tenha a mesma estrutura do "template":
	- chaves que faltam recebem uma cópia do valor do template;
	- chaves com tipo diferente do template (dado corrompido) são trocadas pelo padrão;
	- chaves que existem em data mas não no template são mantidas (compatibilidade futura);
	- se o valor do template é uma tabela VAZIA, ela é tratada como mapa dinâmico
	  (ex.: Inventory) e o conteúdo não é comparado, só o tipo.

	Retorna a própria "data" (alterada no lugar) e a lista de correções feitas,
	no formato "Caminho.Da.Chave: motivo".
]]
function TableUtil.reconcile(data: { [any]: any }, template: { [any]: any }): ({ [any]: any }, { string })
	local fixes: { string } = {}

	local function walk(target: { [any]: any }, model: { [any]: any }, path: string)
		for key, default in model do
			local current = target[key]
			local keyPath = if path == "" then tostring(key) else `{path}.{tostring(key)}`
			if current == nil then
				target[key] = TableUtil.deepCopy(default)
				table.insert(fixes, `{keyPath}: ausente, usando padrão`)
			elseif type(current) ~= type(default) then
				target[key] = TableUtil.deepCopy(default)
				table.insert(fixes, `{keyPath}: tipo {type(current)} inválido (esperado {type(default)}), usando padrão`)
			elseif type(default) == "table" and next(default) ~= nil then
				walk(current, default, keyPath)
			end
		end
	end

	walk(data, template, "")
	return data, fixes
end

return TableUtil
