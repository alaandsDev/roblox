--!strict
--[[
	Fusão (Fase 8): Required unidades IGUAIS (mesmo personagem e mesma variante) viram 1 unidade
	da PRÓXIMA variante (VariantConfig: Normal > Silver > Gold > Diamond > Emerald > Void > Celestial).
	O resultado fica com o MAIOR nível entre as usadas. Travados, favoritos e equipados não entram.
	Custo em dinheiro = BaseIncome * CostSeconds * ordem da variante de destino.
]]
return {
	Required = 3,
	CostSeconds = 600,
}
