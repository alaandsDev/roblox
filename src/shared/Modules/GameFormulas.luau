--!strict
-- Instância única de Formulas com todas as configs do jogo (servidor e cliente).
local Config = script.Parent.Parent.Config
local Formulas = require(script.Parent.Formulas)

return Formulas.new({
	Dice = require(Config.DiceConfig),
	Upgrades = require(Config.UpgradeConfig),
	Roll = require(Config.RollConfig),
	Economy = require(Config.EconomyConfig),
	Characters = require(Config.CharacterConfig),
	Levels = require(Config.CharacterLevelConfig),
	Variants = require(Config.VariantConfig),
})
