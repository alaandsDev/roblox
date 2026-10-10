-- Dá as badges do Config.Badges quando o jogador cumpre a condição.
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Conquistas = {}

-- Badges já entregues (ou já verificadas) nesta sessão, por jogador
local entregues: { [Player]: { [number]: boolean } } = {}

local function entregar(player: Player, badge)
	local ok, possui = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, badge.Id)
	if ok and possui then
		return
	end
	local sucesso, erro = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badge.Id)
	if not sucesso then
		warn(`Falha ao dar a badge "{badge.Nome}" para {player.Name}: {erro}`)
	end
end

function Conquistas.verificar(player: Player, data)
	local lista = entregues[player]
	if not lista then
		lista = {}
		entregues[player] = lista
	end
	for _, badge in Config.Badges do
		if badge.Id ~= 0 and not lista[badge.Id] and badge.Condicao(data) then
			lista[badge.Id] = true
			task.spawn(entregar, player, badge)
		end
	end
end

function Conquistas.remover(player: Player)
	entregues[player] = nil
end

return Conquistas
