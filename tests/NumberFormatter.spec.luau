local T = require("./TestLib")
local F = require("../src/shared/Modules/NumberFormatter")
local describe, it, expect = T.describe, T.it, T.expect

describe("NumberFormatter", function()
	it("abrevia números", function()
		expect(F.abbreviate(0)).toBe("0")
		expect(F.abbreviate(999)).toBe("999")
		expect(F.abbreviate(1000)).toBe("1K")
		expect(F.abbreviate(1234)).toBe("1.23K")
		expect(F.abbreviate(1500000)).toBe("1.5M")
		expect(F.abbreviate(2.5e9)).toBe("2.5B")
		expect(F.abbreviate(1e33)).toBe("1Dc")
	end)

	it("trunca em vez de arredondar para cima", function()
		expect(F.abbreviate(1999)).toBe("1.99K")
		expect(F.abbreviate(999999)).toBe("999.99K")
	end)

	it("negativos, decimais e casas customizadas", function()
		expect(F.abbreviate(-2500)).toBe("-2.5K")
		expect(F.abbreviate(12.345)).toBe("12.34")
		expect(F.abbreviate(1234, 1)).toBe("1.2K")
	end)

	it("valores inválidos e gigantes", function()
		expect(F.abbreviate(0 / 0)).toBe("∞")
		expect(F.abbreviate(math.huge)).toBe("∞")
		expect(F.abbreviate(1e40)).toBe("1.00e+40")
	end)

	it("separador de milhar pt-BR", function()
		expect(F.thousands(1234567)).toBe("1.234.567")
		expect(F.thousands(999)).toBe("999")
		expect(F.thousands(-1000)).toBe("-1.000")
	end)

	it("dinheiro e duração", function()
		expect(F.money(1500)).toBe("$1.5K")
		expect(F.duration(65)).toBe("01:05")
		expect(F.duration(3725)).toBe("1:02:05")
		expect(F.duration(-5)).toBe("00:00")
	end)
end)

return true
