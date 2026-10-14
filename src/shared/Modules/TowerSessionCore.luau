--!strict
--[[
	TowerSessionCore (puro): estado de UMA sessão contínua de Torre por jogador.
	O servidor (TowerService) é dono da sessão; o cliente só pede START / PRÓXIMO / AUTO / PARAR e
	recebe o resultado de cada estágio. O cliente nunca declara vitória, recompensa nem andar.

	Fluxo:
	    start -> "running" -> estágio (luta no servidor) -> applyResult
	        vitória : recompensa UMA vez por andar; próximo andar
	                  AUTO  -> continua "running" (próximo estágio depois de StageInterval)
	                  manual-> "paused" (espera PRÓXIMO, que vira "running")
	        derrota : fim ("defeat") — NUNCA recomeça do andar 1 sozinho
	        torre completa / MaxStagesPerSession / parar / desconectar / inválido: fim
	Status: "running" | "paused" | "ended"
]]

local TowerSessionCore = {}

export type Session = {
	id: number,
	towerId: string,
	nextFloor: number,
	maxFloor: number,
	auto: boolean,
	status: string,
	endReason: string?,
	stages: number,
	maxStages: number,
	lastStageAt: number,
	rewarded: { [number]: boolean },
	totals: { money: number, gems: number, floors: number },
	teamHp: number, -- fração (0..1) do HP do time no fim do último estágio
}

local nextId = 0

function TowerSessionCore.new(towerId: string, highest: number, maxFloor: number, auto: boolean, maxStages: number): (Session?, string?)
	if highest >= maxFloor then
		return nil, "tower_complete"
	end
	nextId += 1
	return {
		id = nextId,
		towerId = towerId,
		nextFloor = highest + 1,
		maxFloor = maxFloor,
		auto = auto == true,
		status = "running",
		endReason = nil,
		stages = 0,
		maxStages = maxStages,
		lastStageAt = -math.huge,
		rewarded = {},
		totals = { money = 0, gems = 0, floors = 0 },
		teamHp = 1,
	},
		nil
end

function TowerSessionCore.isActive(session: Session?): boolean
	return session ~= nil and session.status ~= "ended"
end

-- Pode lutar o próximo estágio agora? (estado + intervalo mínimo entre estágios)
function TowerSessionCore.canFight(session: Session, now: number, interval: number): (boolean, string?)
	if session.status ~= "running" then
		return false, "not_running"
	end
	if session.nextFloor > session.maxFloor then
		return false, "tower_complete"
	end
	if session.stages >= session.maxStages then
		return false, "session_limit"
	end
	if now - session.lastStageAt < interval then
		return false, "cooldown"
	end
	return true, nil
end

function TowerSessionCore.stop(session: Session, reason: string)
	if session.status ~= "ended" then
		session.status = "ended"
		session.endReason = reason
	end
end

--[[
	Registra o resultado do estágio `floor` (calculado pelo servidor). Idempotente: o mesmo andar
	nunca é recompensado duas vezes e um andar diferente do esperado é recusado.
	Devolve true se aceitou (e o chamador deve ENTREGAR a recompensa), false se ignorou.
]]
function TowerSessionCore.applyResult(session: Session, floor: number, won: boolean, rewards: { money: number, gems: number }, teamHp: number, now: number): boolean
	if session.status ~= "running" or floor ~= session.nextFloor or session.rewarded[floor] then
		return false
	end
	session.stages += 1
	session.lastStageAt = now
	session.teamHp = math.clamp(teamHp, 0, 1)
	if not won then
		TowerSessionCore.stop(session, "defeat")
		return true
	end
	session.rewarded[floor] = true
	session.totals.money += math.max(0, rewards.money)
	session.totals.gems += math.max(0, rewards.gems)
	session.totals.floors += 1
	session.nextFloor = floor + 1
	if session.nextFloor > session.maxFloor then
		TowerSessionCore.stop(session, "tower_complete")
	elseif session.stages >= session.maxStages then
		TowerSessionCore.stop(session, "session_limit")
	elseif not session.auto then
		session.status = "paused"
	end
	return true
end

-- PRÓXIMO (modo manual) ou ligar o AUTO durante a pausa
function TowerSessionCore.resume(session: Session): boolean
	if session.status == "paused" then
		session.status = "running"
		return true
	end
	return false
end

function TowerSessionCore.setAuto(session: Session, auto: boolean)
	session.auto = auto == true
	if session.auto then
		TowerSessionCore.resume(session)
	end
end

-- Resumo enviado ao cliente (painel compacto do OCULTAR)
function TowerSessionCore.summary(session: Session): any
	return {
		id = session.id,
		tower = session.towerId,
		floor = session.nextFloor,
		maxFloor = session.maxFloor,
		auto = session.auto,
		status = session.status,
		endReason = session.endReason,
		stages = session.stages,
		teamHp = session.teamHp,
		money = session.totals.money,
		gems = session.totals.gems,
		floors = session.totals.floors,
	}
end

return TowerSessionCore
