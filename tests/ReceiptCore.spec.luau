local T = require("./TestLib")
local ReceiptCore = require("../src/server/Core/ReceiptCore")
local describe, it, expect = T.describe, T.it, T.expect

local function setup()
	local env = {
		profile = { Data = { ProcessedReceipts = {}, Gems = 0 } },
		loaded = true,
		saveWorks = true,
		saves = 0,
		deliveries = 0,
	}
	env.ctx = {
		getProfile = function(playerId)
			return if env.loaded and playerId == 1 then env.profile else nil
		end,
		getHandler = function(productId)
			if productId == 100 then
				return function(profile)
					env.deliveries += 1
					profile.Data.Gems += 10
					return true
				end
			elseif productId == 200 then
				return function()
					error("falha simulada")
				end
			end
			return nil
		end,
		save = function()
			env.saves += 1
			return env.saveWorks
		end,
		pending = {},
		historySize = 3,
	}
	return env
end

local function receipt(id, product)
	return { PlayerId = 1, ProductId = product or 100, PurchaseId = id }
end

describe("ReceiptCore (idempotência)", function()
	it("jogador sem perfil carregado -> tenta depois", function()
		local env = setup()
		env.loaded = false
		expect(ReceiptCore.process(receipt("p1"), env.ctx)).toBe(ReceiptCore.NotProcessed)
		expect(env.deliveries).toBe(0)
	end)

	it("primeira vez entrega e confirma", function()
		local env = setup()
		expect(ReceiptCore.process(receipt("p1"), env.ctx)).toBe(ReceiptCore.Granted)
		expect(env.profile.Data.Gems).toBe(10)
		expect(env.profile.Data.ProcessedReceipts[1]).toBe("p1")
	end)

	it("mesma compra repetida NÃO entrega de novo", function()
		local env = setup()
		ReceiptCore.process(receipt("p1"), env.ctx)
		expect(ReceiptCore.process(receipt("p1"), env.ctx)).toBe(ReceiptCore.Granted)
		expect(ReceiptCore.process(receipt("p1"), env.ctx)).toBe(ReceiptCore.Granted)
		expect(env.deliveries).toBe(1)
		expect(env.profile.Data.Gems).toBe(10)
	end)

	it("produto desconhecido não é confirmado", function()
		local env = setup()
		expect(ReceiptCore.process(receipt("p1", 999), env.ctx)).toBe(ReceiptCore.NotProcessed)
		expect(#env.profile.Data.ProcessedReceipts).toBe(0)
	end)

	it("erro ao entregar não confirma nem registra", function()
		local env = setup()
		expect(ReceiptCore.process(receipt("p1", 200), env.ctx)).toBe(ReceiptCore.NotProcessed)
		expect(#env.profile.Data.ProcessedReceipts).toBe(0)
	end)

	it("save falhou: não confirma; na repetição salva sem entregar de novo", function()
		local env = setup()
		env.saveWorks = false
		expect(ReceiptCore.process(receipt("p1"), env.ctx)).toBe(ReceiptCore.NotProcessed)
		expect(env.deliveries).toBe(1)
		expect(env.ctx.pending["p1"]).toBe(true)

		-- Roblox tenta de novo, save ainda falha
		expect(ReceiptCore.process(receipt("p1"), env.ctx)).toBe(ReceiptCore.NotProcessed)
		-- Agora o save funciona
		env.saveWorks = true
		expect(ReceiptCore.process(receipt("p1"), env.ctx)).toBe(ReceiptCore.Granted)
		expect(env.deliveries).toBe(1)
		expect(env.ctx.pending["p1"]).toBeNil()
	end)

	it("histórico é limitado ao tamanho configurado", function()
		local env = setup()
		for i = 1, 5 do
			ReceiptCore.process(receipt("p" .. i), env.ctx)
		end
		expect(#env.profile.Data.ProcessedReceipts).toBe(3)
		expect(env.profile.Data.ProcessedReceipts[1]).toBe("p3")
	end)
end)

return true
