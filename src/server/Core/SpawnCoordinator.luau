--!strict
--[[
	Decide QUANDO carregar/posicionar o personagem de cada jogador (puro, testável fora do Roblox).
	Evita a corrida entre "personagem apareceu" e "base atribuída":

	- O personagem só é carregado quando a base já foi atribuída (ou, depois de um tempo
	  limite, sem base: vai para o Hub e é levado para casa quando a base sair).
	- O personagem só é posicionado quando ele existe, o HumanoidRootPart existe, a base
	  está atribuída E o dono da base é ele mesmo (nunca nasce na base de outro).
	- Morte: o servidor recarrega o personagem depois do tempo de respawn.

	O BaseService chama os eventos (playerJoined, baseAssigned, characterAdded, rootReady,
	died, respawnDue, fallbackDue, playerLeft); as ações saem pelas funções injetadas:
	    deps.loadCharacter(player)          -- carrega o personagem (nasce no RespawnLocation)
	    deps.placeAtBase(player, baseId)    -- posiciona na entrada da base, olhando para dentro
	    deps.ownerOf(baseId) -> userId?     -- dono real da base (associação Player -> Base)
]]

local SpawnCoordinator = {}
SpawnCoordinator.__index = SpawnCoordinator

export type Deps = {
	loadCharacter: (player: any) -> (),
	placeAtBase: (player: any, baseId: number) -> (),
	ownerOf: (baseId: number) -> number?,
}

type State = {
	baseId: number?,
	hasCharacter: boolean,
	rootReady: boolean,
	loading: boolean,
	placed: boolean,
}

function SpawnCoordinator.new(deps: Deps): any
	return setmetatable({ deps = deps, states = {} :: { [any]: State } }, SpawnCoordinator)
end

function SpawnCoordinator:_state(player: any): State?
	return self.states[player]
end

function SpawnCoordinator:_load(state: State, player: any)
	if state.loading or state.hasCharacter then
		return
	end
	state.loading = true
	self.deps.loadCharacter(player)
end

-- Posiciona só se tudo estiver pronto e a base for MESMO deste jogador
function SpawnCoordinator:_tryPlace(state: State, player: any)
	local baseId = state.baseId
	if not baseId or not state.hasCharacter or not state.rootReady or state.placed then
		return
	end
	if self.deps.ownerOf(baseId) ~= player.UserId then
		return
	end
	state.placed = true
	self.deps.placeAtBase(player, baseId)
end

-- Idempotente: pode ser chamado mais de uma vez sem perder o estado
function SpawnCoordinator:playerJoined(player: any): State
	local state = self.states[player]
	if not state then
		state = { baseId = nil, hasCharacter = false, rootReady = false, loading = false, placed = false }
		self.states[player] = state
	end
	return state
end

function SpawnCoordinator:baseAssigned(player: any, baseId: number)
	-- A base pode chegar antes do registro do jogador (ordem dos PlayerAdded): cria o estado
	local state = self:playerJoined(player)
	state.baseId = baseId
	if state.hasCharacter then
		-- Já tinha personagem (ex.: nasceu no Hub pelo tempo limite): leva para casa
		state.placed = false
		self:_tryPlace(state, player)
	else
		self:_load(state, player)
	end
end

-- Base não veio a tempo (dados lentos ou servidor cheio): nasce no Hub
function SpawnCoordinator:fallbackDue(player: any)
	local state = self:_state(player)
	if state and not state.baseId then
		self:_load(state, player)
	end
end

function SpawnCoordinator:characterAdded(player: any)
	local state = self:playerJoined(player)
	state.loading = false
	state.hasCharacter = true
	state.rootReady = false
	state.placed = false
end

function SpawnCoordinator:rootReady(player: any)
	local state = self:_state(player)
	if not state or not state.hasCharacter then
		return
	end
	state.rootReady = true
	self:_tryPlace(state, player)
end

function SpawnCoordinator:died(player: any)
	local state = self:_state(player)
	if state then
		state.hasCharacter = false
		state.rootReady = false
		state.placed = false
	end
end

-- Chamado depois do tempo de respawn
function SpawnCoordinator:respawnDue(player: any)
	local state = self:_state(player)
	if state and not state.hasCharacter then
		self:_load(state, player)
	end
end

function SpawnCoordinator:playerLeft(player: any)
	self.states[player] = nil
end

return SpawnCoordinator
