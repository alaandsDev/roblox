--[[
	Auditoria da RENDA POR DICE (não altera nada; lê os configs reais).
	    lune run tools/sim/analyze_dice_income.luau table  <saida.json>
	    lune run tools/sim/analyze_dice_income.luau sim    <saida.json> <perfil> <horasAtivas> <sementes>
	table: os 112 personagens F2P (Dice, ordem, id, raridade, BaseIncome, renda Nv1 e Nv30 Normal)
	       + agrupamento Dice × Raridade + rendas IGUAIS entre Dice diferentes.
	sim:   EconomyModel (o simulador oficial) por perfil: tempo ativo para comprar cada Dice,
	       tempo em que os rolls exigidos foram atingidos (gargalo = dinheiro ou rolls),
	       Rebirths, renda/s e ganhos por fonte (coletor, offline, torre, venda...).
	Python junta tudo: tools/sim/run_dice_income_audit.py -> DICE_INCOME_AUDIT.md
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local EconomyModel = require("./EconomyModel")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")
local RarityConfig = require("../../src/shared/Config/RarityConfig")
local LevelConfig = require("../../src/shared/Config/CharacterLevelConfig")

local mode = process.args[1]
local out = process.args[2]
local core = EconomyModel.core
local formulas = EconomyModel.formulas

if mode == "table" then
	local rows = {}
	for order, dice in core:diceList() do
		for _, id in core:charactersFor(dice.Id) do
			local c = CharacterConfig.ById[id]
			table.insert(rows, {
				dice = dice.Id,
				order = order,
				id = id,
				rarity = c.Rarity,
				tier = RarityConfig.ById[c.Rarity].Tier,
				baseIncome = c.BaseIncome,
				incomeL1 = formulas:unitIncome({ Id = id, Level = 1, Variant = "Normal" }),
				incomeL30 = formulas:unitIncome({ Id = id, Level = LevelConfig.MaxLevel, Variant = "Normal" }),
				upgradeToMax = (formulas:characterUpgradeCost(id, 1, LevelConfig.MaxLevel - 1)),
				sell = formulas:sellValue(id, "Normal"),
			})
		end
	end
	fs.writeFile(out, serde.encode("json", { rows = rows, maxLevel = LevelConfig.MaxLevel }, false))
	print(`{#rows} personagens F2P`)
elseif mode == "sim" then
	local profileName = process.args[3]
	local hours = tonumber(process.args[4]) or 30
	local seeds = tonumber(process.args[5]) or 6
	local profile = EconomyModel.Profiles[profileName]
	local runs = {}
	for seed = 1, seeds do
		local r = EconomyModel.run(profile, hours * 3600, 1000 + seed, { checkpoints = {} })
		local p = r.player
		table.insert(runs, {
			ownedAt = p.ownedAt,
			rollUnlockAt = p.rollUnlockAt,
			diceOwned = p.diceOwned,
			rebirthTimes = p.rebirthTimes,
			earned = p.earned,
			spent = p.spent,
			ips = p.ipsCache,
			days = r.days,
			rolls = p.rolls,
		})
	end
	local dice = {}
	for _, d in core:diceList() do
		table.insert(dice, { id = d.Id, price = d.Price, rolls = d.UnlockRequirement.Rolls or 0 })
	end
	fs.writeFile(out, serde.encode("json", { profile = profileName, hours = hours, runs = runs, dice = dice }, false))
	print(`{profileName}: {seeds} jogadores x {hours} h ativas`)
end
