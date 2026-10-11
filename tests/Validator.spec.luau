local T = require("./TestLib")
local Validator = require("../src/shared/Modules/Validator")
local Definitions = require("../src/shared/Remotes/Definitions")
local describe, it, expect = T.describe, T.it, T.expect

local function check(rules, ...)
	return (Validator.validateArgs({ ... }, select("#", ...), rules))
end

describe("Validator (payload)", function()
	it("números: tipo, intervalo, inteiro, NaN/inf", function()
		local rules = { { type = "number", min = 0, max = 10, integer = true } }
		expect(check(rules, 5)).toBeTruthy()
		expect(check(rules, "5")).toBeFalsy()
		expect(check(rules, -1)).toBeFalsy()
		expect(check(rules, 11)).toBeFalsy()
		expect(check(rules, 2.5)).toBeFalsy()
		expect(check(rules, 0 / 0)).toBeFalsy()
		expect(check(rules, math.huge)).toBeFalsy()
	end)

	it("strings: tamanho, enum, UTF-8", function()
		local rules = { { type = "string", maxLength = 5, enum = { "abc", "xyz" } } }
		expect(check(rules, "abc")).toBeTruthy()
		expect(check(rules, "outro")).toBeFalsy()
		expect(check({ { type = "string", maxLength = 3 } }, "abcd")).toBeFalsy()
		expect(check({ { type = "string" } }, "\255\254")).toBeFalsy()
		expect(check({ { type = "string" } }, string.rep("a", 1000))).toBeFalsy() -- limite padrão
	end)

	it("booleanos e argumentos obrigatórios/opcionais", function()
		expect(check({ { type = "boolean" } }, true)).toBeTruthy()
		expect(check({ { type = "boolean" } }, 1)).toBeFalsy()
		expect(check({ { type = "boolean" } })).toBeFalsy()
		expect(check({ { type = "boolean", optional = true } })).toBeTruthy()
	end)

	it("rejeita argumentos extras", function()
		expect(check({}, "a")).toBeFalsy()
		expect(check({ { type = "boolean" } }, true, "extra")).toBeFalsy()
		expect(check({}, nil)).toBeFalsy() -- nil explícito também conta
	end)

	it("listas: itens, buracos, tamanho máximo", function()
		local rules = { { type = "array", maxItems = 3, of = { type = "string", maxLength = 4 } } }
		expect(check(rules, { "a", "b" })).toBeTruthy()
		expect(check(rules, { "a", 1 })).toBeFalsy()
		expect(check(rules, { "a", "b", "c", "d" })).toBeFalsy()
		expect(check(rules, { [1] = "a", [3] = "c" })).toBeFalsy()
		expect(check(rules, { x = "a" })).toBeFalsy()
		expect(check(rules, "a")).toBeFalsy()
	end)

	it("todas as definições de remotes são válidas", function()
		local count = 0
		for name, def in Definitions.Requests do
			count += 1
			expect(type(def.args) == "table").toBeTruthy()
			expect(type(def.rate) == "table" and def.rate.capacity > 0 and def.rate.refill >= 0).toBeTruthy()
			for i, rule in def.args do
				if not Validator.isValidRule(rule) then
					error(`regra inválida em {name} arg{i}`)
				end
			end
		end
		expect(count >= 9).toBeTruthy()
		for _, name in { "RequestRoll", "RequestEquipCharacter", "RequestSellCharacter", "RequestEquipDice", "RequestUpgrade", "RequestEnterTower" } do
			expect(Definitions.Requests[name] ~= nil).toBeTruthy()
		end
	end)
end)

return true
