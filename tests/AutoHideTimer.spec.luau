-- RECENT ROLLS: some 20 s depois do último roll (AutoHideTimer, tempos exatos)
local T = require("./TestLib")
local AutoHideTimer = require("../src/shared/Modules/AutoHideTimer")
local describe, it, expect = T.describe, T.it, T.expect

describe("Recent Rolls: auto-hide de 20 s", function()
	it("T=0 roll -> visível; 19,9 s -> visível; 20,0 s -> esconde", function()
		local t = AutoHideTimer.new(20)
		expect(t:visible(0)).toBe(false) -- nunca rolou: nada a mostrar
		t:bump(0)
		expect(t:visible(0)).toBe(true)
		expect(t:visible(19.9)).toBe(true)
		expect(t:visible(20.0)).toBe(false)
	end)

	it("novo roll reaparece na hora e reinicia o contador", function()
		local t = AutoHideTimer.new(20)
		t:bump(0)
		expect(t:visible(25)).toBe(false)
		t:bump(25)
		expect(t:visible(25)).toBe(true)
		expect(t:remaining(25)).toBe(20)
	end)

	it("roll aos 10 s reinicia: aos 29 s (19 s do 2º) visível; aos 30 s (20 s do 2º) esconde", function()
		local t = AutoHideTimer.new(20)
		t:bump(0)
		t:bump(10)
		expect(t:visible(29)).toBe(true)
		expect(t:visible(30)).toBe(false)
	end)

	it("AUTO rolando sem parar (1 roll/s ou Roll Rápido 0,5 s) nunca esconde", function()
		for _, interval in { 1, 0.5 } do
			local t = AutoHideTimer.new(20)
			local now = 0
			while now <= 300 do
				t:bump(now)
				expect(t:visible(now + interval * 0.99)).toBe(true)
				now += interval
			end
			-- AUTO desligado: 20 s depois do último resultado some
			local last = now - interval
			expect(t:visible(last + 19.99)).toBe(true)
			expect(t:visible(last + 20)).toBe(false)
		end
	end)
end)

return true
