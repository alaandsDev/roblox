-- Valores de balanceamento do simulator. Ajuste aqui para mudar a economia do jogo.
local Config = {}

Config.StartingData = {
	Energia = 0,
	Moedas = 0,
	Rebirths = 0,
	ClickPower = 1,
	Capacidade = 50,
}

-- Tempo mínimo (segundos) entre cliques aceitos pelo servidor
Config.ClickCooldown = 0.1

-- Moedas recebidas por unidade de energia vendida
Config.SellRate = 1

Config.RebirthBaseCost = 1000
Config.RebirthBonus = 0.5 -- +50% de multiplicador por rebirth

Config.Upgrades = {
	ClickPower = { Nome = "Força", CustoBase = 25, Crescimento = 1.5, Incremento = 1 },
	Capacidade = { Nome = "Mochila", CustoBase = 50, Crescimento = 1.6, Incremento = 50 },
}

function Config.multiplier(rebirths: number): number
	return 1 + rebirths * Config.RebirthBonus
end

function Config.upgradeCost(upgradeId: string, currentValue: number): number
	local upgrade = Config.Upgrades[upgradeId]
	local level = (currentValue - Config.StartingData[upgradeId]) / upgrade.Incremento
	return math.floor(upgrade.CustoBase * upgrade.Crescimento ^ level)
end

function Config.rebirthCost(rebirths: number): number
	return Config.RebirthBaseCost * (rebirths + 1) ^ 2
end

function Config.clickGain(clickPower: number, rebirths: number): number
	return math.floor(clickPower * Config.multiplier(rebirths))
end

return Config
