--!strict
--[[
	Fusão (Fase 8, revisada na auditoria): N unidades IGUAIS (mesmo personagem e mesma variante)
	viram 1 da PRÓXIMA variante (VariantConfig: Normal > Silver > Gold > Diamond > Emerald > Void > Celestial).
	Quantas são necessárias depende da variante de DESTINO (RequiredByTarget):
	    Prata 3 · Ouro 3 · Diamante 3 · Esmeralda 2 · Vazio 2 · Celestial 2
	    Cópias Normais acumuladas: Prata 3 · Ouro 9 · Diamante 27 · Esmeralda 54 · Vazio 108 · Celestial 216
	(antes: 3 em todas = 729 para Celestial — matematicamente absurdo para raridades altas).
	O resultado fica com o MAIOR nível entre as usadas. Travados, favoritos, equipados e itens
	em uma troca não entram. Custo em dinheiro = BaseIncome * CostSeconds * ordem da variante de destino.
]]
return {
	RequiredByTarget = { Silver = 3, Gold = 3, Diamond = 3, Emerald = 2, Void = 2, Celestial = 2 },
	-- Maior quantidade possível num pedido (validação do remote)
	MaxRequired = 3,
	CostSeconds = 600,
}
