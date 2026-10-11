--!strict
--[[
	Lógica idempotente do ProcessReceipt (pura, testável fora do Roblox).

	Regras:
	1. Jogador fora do servidor ou perfil não carregado -> NotProcessed (o Roblox tenta de novo depois).
	2. PurchaseId já registrado e já salvo -> Granted (não entrega de novo).
	3. Produto sem entregador registrado -> NotProcessed (nunca confirma o que não entregou).
	4. Entrega + registra o PurchaseId no perfil + SALVA. Só confirma (Granted) se o save deu certo.
	   Se o save falhar, o PurchaseId fica "pendente" na memória: na próxima tentativa do Roblox
	   salvamos de novo, sem entregar outra vez.
]]

local ReceiptCore = {}

ReceiptCore.Granted = "Granted"
ReceiptCore.NotProcessed = "NotProcessed"

export type ReceiptInfo = { PlayerId: number, ProductId: number, PurchaseId: string }

export type Context = {
	getProfile: (playerId: number) -> any?,
	-- Devolve a função que entrega o produto, ou nil se não existe
	getHandler: (productId: number) -> ((profile: any, info: ReceiptInfo) -> boolean)?,
	save: (profile: any, info: ReceiptInfo) -> boolean,
	-- PurchaseIds entregues mas ainda não salvos (memória do servidor)
	pending: { [string]: boolean },
	historySize: number,
	log: ((level: string, message: string) -> ())?,
}

local function log(ctx: Context, level: string, message: string)
	if ctx.log then
		ctx.log(level, message)
	end
end

function ReceiptCore.process(info: ReceiptInfo, ctx: Context): string
	local profile = ctx.getProfile(info.PlayerId)
	if not profile then
		return ReceiptCore.NotProcessed
	end

	local history: { string } = profile.Data.ProcessedReceipts
	if table.find(history, info.PurchaseId) then
		if ctx.pending[info.PurchaseId] then
			if not ctx.save(profile, info) then
				return ReceiptCore.NotProcessed
			end
			ctx.pending[info.PurchaseId] = nil
		end
		return ReceiptCore.Granted
	end

	local handler = ctx.getHandler(info.ProductId)
	if not handler then
		log(ctx, "warn", `produto {info.ProductId} sem entregador registrado`)
		return ReceiptCore.NotProcessed
	end

	local ok, delivered = pcall(handler, profile, info)
	if not ok or delivered == false then
		log(ctx, "error", `falha ao entregar produto {info.ProductId}: {tostring(delivered)}`)
		return ReceiptCore.NotProcessed
	end

	table.insert(history, info.PurchaseId)
	while #history > ctx.historySize do
		table.remove(history, 1)
	end

	if ctx.save(profile, info) then
		return ReceiptCore.Granted
	end
	ctx.pending[info.PurchaseId] = true
	return ReceiptCore.NotProcessed
end

return ReceiptCore
