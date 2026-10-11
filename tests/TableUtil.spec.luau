local T = require("./TestLib")
local TableUtil = require("../src/shared/Modules/TableUtil")
local describe, it, expect = T.describe, T.it, T.expect

describe("TableUtil", function()
	it("deepCopy cria cópia independente", function()
		local a = { x = { y = 1 }, lista = { 1, 2 } }
		local b = TableUtil.deepCopy(a)
		b.x.y = 2
		table.insert(b.lista, 3)
		expect(a.x.y).toBe(1)
		expect(#a.lista).toBe(2)
	end)

	it("deepEqual compara estrutura", function()
		expect(TableUtil.deepEqual({ a = { 1, 2 } }, { a = { 1, 2 } })).toBeTruthy()
		expect(TableUtil.deepEqual({ a = 1 }, { a = 1, b = 2 })).toBeFalsy()
	end)

	it("reconcile completa chaves ausentes (deep merge)", function()
		local template = { Money = 0, Settings = { AutoRoll = false, HideRollAnimation = false } }
		local data = { Money = 50, Settings = { AutoRoll = true } }
		local result, fixes = TableUtil.reconcile(data, template)
		expect(result.Money).toBe(50)
		expect(result.Settings.AutoRoll).toBe(true)
		expect(result.Settings.HideRollAnimation).toBe(false)
		expect(#fixes).toBe(1)
	end)

	it("reconcile troca valor com tipo errado (dado corrompido)", function()
		local data = TableUtil.reconcile({ Money = "muito" }, { Money = 0 })
		expect(data.Money).toBe(0)
	end)

	it("reconcile mantém chaves desconhecidas (compatibilidade futura)", function()
		local data = TableUtil.reconcile({ Novo = 1 }, { Money = 0 })
		expect(data.Novo).toBe(1)
	end)

	it("reconcile não mexe no conteúdo de mapas dinâmicos (tabela vazia no template)", function()
		local data = TableUtil.reconcile({ Inventory = { abc = { Id = "X" } } }, { Inventory = {} })
		expect(data.Inventory.abc.Id).toBe("X")
	end)

	it("reconcile não altera o template", function()
		local template = { Settings = { AutoSell = {} } }
		local data = TableUtil.reconcile({}, template)
		data.Settings.AutoSell.Common = true
		expect(template.Settings.AutoSell.Common).toBeNil()
	end)
end)

return true
