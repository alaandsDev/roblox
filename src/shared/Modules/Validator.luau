--!strict
-- Validação dos argumentos que chegam do cliente. Módulo puro.
--
-- Cada argumento é descrito por uma regra:
--   { type = "number", min = 0, max = 100, integer = true }
--   { type = "string", maxLength = 32, enum = { "A", "B" } }
--   { type = "boolean" }
--   { type = "array", maxItems = 50, of = <regra> }
--   qualquer regra pode ter optional = true
-- Nunca confie em nada que vem do cliente: tipos, tamanhos e quantidades são checados.

local Validator = {}

export type Rule = {
	type: string,
	optional: boolean?,
	min: number?,
	max: number?,
	integer: boolean?,
	maxLength: number?,
	enum: { string }?,
	maxItems: number?,
	of: Rule?,
}

local MAX_STRING_DEFAULT = 64

local function checkValue(value: any, rule: Rule, label: string): (boolean, string?)
	if value == nil then
		if rule.optional then
			return true
		end
		return false, `{label}: obrigatório`
	end

	local kind = rule.type
	if kind == "number" then
		if type(value) ~= "number" then
			return false, `{label}: esperado number`
		end
		if value ~= value or value == math.huge or value == -math.huge then
			return false, `{label}: número inválido`
		end
		if rule.integer and value % 1 ~= 0 then
			return false, `{label}: esperado inteiro`
		end
		if rule.min and value < rule.min then
			return false, `{label}: menor que {rule.min}`
		end
		if rule.max and value > rule.max then
			return false, `{label}: maior que {rule.max}`
		end
		return true
	elseif kind == "string" then
		if type(value) ~= "string" then
			return false, `{label}: esperado string`
		end
		if #value > (rule.maxLength or MAX_STRING_DEFAULT) then
			return false, `{label}: texto longo demais`
		end
		if utf8.len(value) == nil then
			return false, `{label}: UTF-8 inválido`
		end
		if rule.enum and not table.find(rule.enum, value) then
			return false, `{label}: valor não permitido`
		end
		return true
	elseif kind == "boolean" then
		if type(value) ~= "boolean" then
			return false, `{label}: esperado boolean`
		end
		return true
	elseif kind == "array" then
		if type(value) ~= "table" then
			return false, `{label}: esperado lista`
		end
		local count = 0
		for key in value do
			count += 1
			if type(key) ~= "number" or key % 1 ~= 0 or key < 1 then
				return false, `{label}: lista com chaves inválidas`
			end
		end
		if count ~= #value then
			return false, `{label}: lista com buracos`
		end
		if count > (rule.maxItems or 100) then
			return false, `{label}: itens demais`
		end
		if rule.of then
			for i, item in value do
				local ok, err = checkValue(item, rule.of, `{label}[{i}]`)
				if not ok then
					return false, err
				end
			end
		end
		return true
	end
	return false, `{label}: tipo de regra desconhecido "{tostring(kind)}"`
end

-- Valida uma lista de argumentos. "count" é select("#", ...) para detectar argumentos extras.
function Validator.validateArgs(args: { any }, count: number, rules: { Rule }): (boolean, string?)
	if count > #rules then
		return false, `argumentos demais ({count}, máximo {#rules})`
	end
	for i, rule in rules do
		local ok, err = checkValue(args[i], rule, `arg{i}`)
		if not ok then
			return false, err
		end
	end
	return true
end

-- Confere se uma regra está bem escrita (usado nos testes das definições de remotes).
function Validator.isValidRule(rule: any): boolean
	if type(rule) ~= "table" then
		return false
	end
	local kind = rule.type
	if kind == "array" then
		return rule.of == nil or Validator.isValidRule(rule.of)
	end
	return kind == "number" or kind == "string" or kind == "boolean"
end

return Validator
