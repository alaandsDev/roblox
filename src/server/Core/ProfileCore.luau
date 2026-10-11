--!strict
--[[
	Núcleo do salvamento de perfis (sem dependência do Roblox: o DataStore, o relógio,
	o "wait" e o log são injetados, o que permite testar tudo fora do Studio).

	Formato gravado no DataStore (uma chave por jogador):
	{
		Data = { ...perfil do jogador (DataConfig.Template)... },
		Meta = {
			SessionLock = { JobId = "...", LockedAt = 1700000000 } | nil,
			SavedAt = 1700000000,
			CorruptBackup = <valor ilegível encontrado antes, se houver>,
		},
	}

	Garantias:
	- Tudo via UpdateAsync (nunca SetAsync): não sobrescreve escrita de outro servidor às cegas.
	- Trava de sessão: só um servidor por vez pode carregar/salvar o perfil.
	  Trava sem renovação há mais de lockTimeout = servidor caído, pode ser assumida.
	- Versão de schema + migrações; versão MAIS NOVA que a do servidor = não carrega
	  (um servidor antigo nunca estraga um save novo).
	- Repetição com espera exponencial em erros do DataStore.
	- Dado ilegível nunca é descartado em silêncio: vai para Meta.CorruptBackup + log de erro.
]]

local ProfileCore = {}
ProfileCore.__index = ProfileCore

export type Store = {
	UpdateAsync: (self: any, key: string, transform: (any) -> any) -> any,
}

export type Options = {
	store: Store,
	jobId: string,
	template: { [string]: any },
	version: number,
	migrations: { [number]: (any) -> any },
	lockTimeout: number,
	maxAttempts: number,
	retryBaseDelay: number,
	receiptHistory: number?,
	now: () -> number,
	wait: (seconds: number) -> (),
	log: ((level: string, message: string) -> ())?,
	-- Funções de tabela (TableUtil), injetadas para o módulo continuar puro
	deepCopy: (any) -> any,
	reconcile: (data: any, template: any) -> (any, { string }),
}

export type Profile = {
	Key: string,
	Data: { [string]: any },
	Meta: { [string]: any },
	IsNew: boolean,
	-- true quando outro servidor assumiu a trava: paramos de salvar
	LockLost: boolean,
	-- true depois de liberar a trava (saída do jogador)
	Released: boolean,
}

-- Motivos de falha devolvidos por load/save
ProfileCore.Reasons = {
	Locked = "LOCKED",
	FutureVersion = "FUTURE_VERSION",
	Error = "ERROR",
	LockLost = "LOCK_LOST",
	Released = "RELEASED",
}

function ProfileCore.new(options: Options)
	return setmetatable({ o = options }, ProfileCore)
end

function ProfileCore:_log(level: string, message: string)
	if self.o.log then
		self.o.log(level, message)
	end
end

-- Executa UpdateAsync com repetição exponencial em caso de erro (não em caso de recusa)
function ProfileCore:_update(key: string, transform: (any) -> any): (boolean, any)
	local o: Options = self.o
	local lastError: any
	for attempt = 1, o.maxAttempts do
		local ok, result = pcall(o.store.UpdateAsync, o.store, key, transform)
		if ok then
			return true, result
		end
		lastError = result
		self:_log("warn", `UpdateAsync falhou ({attempt}/{o.maxAttempts}) para {key}: {tostring(result)}`)
		if attempt < o.maxAttempts then
			o.wait(o.retryBaseDelay * 2 ^ (attempt - 1))
		end
	end
	return false, lastError
end

-- Aplica migrações + completa com o template. Retorna nil se a versão é do futuro.
function ProfileCore:_prepare(data: { [string]: any }): { [string]: any }?
	local o: Options = self.o
	if type(data.Version) ~= "number" then
		self:_log("warn", "perfil sem Version, assumindo 1")
		data.Version = 1
	end
	if data.Version > o.version then
		return nil
	end
	while data.Version < o.version do
		local target = data.Version + 1
		local migrate = o.migrations[target]
		if migrate then
			data = migrate(data) or data
		end
		data.Version = target
		self:_log("info", `perfil migrado para a versão {target}`)
	end
	local _, fixes = o.reconcile(data, o.template)
	for _, fix in fixes do
		self:_log("debug", `reconcile: {fix}`)
	end
	return data
end

--[[
	Carrega o perfil e assume a trava de sessão.
	Retorna (profile, nil) ou (nil, motivo).
	Se outro servidor tem a trava ativa, espera e tenta de novo (até maxAttempts vezes),
	porque normalmente ele está só terminando de salvar a saída do jogador.
]]
function ProfileCore:load(key: string): (Profile?, string?)
	local o: Options = self.o
	for attempt = 1, o.maxAttempts do
		local outcome: string? = nil
		local isNew = false

		local ok, record = self:_update(key, function(old: any): any
			outcome = nil
			isNew = false
			local now: number = o.now()
			local rec: { [string]: any }

			if old == nil then
				rec = { Meta = {} }
			elseif type(old) ~= "table" then
				-- Valor ilegível: guarda como backup e começa do zero, sem descartar nada
				rec = { Meta = { CorruptBackup = old } }
				self:_log("error", `dado ilegível em {key} (tipo {type(old)}), backup em Meta.CorruptBackup`)
			else
				rec = old
				if type(rec.Meta) ~= "table" then
					rec.Meta = {}
				end
			end

			local lock = rec.Meta.SessionLock
			if type(lock) == "table" and lock.JobId ~= o.jobId and type(lock.LockedAt) == "number" then
				if now - lock.LockedAt < o.lockTimeout then
					outcome = ProfileCore.Reasons.Locked
					return nil -- cancela a escrita
				end
				self:_log("warn", `trava velha de {tostring(lock.JobId)} em {key} foi assumida`)
			end

			local data = rec.Data
			if type(data) ~= "table" then
				if data ~= nil then
					rec.Meta.CorruptBackup = data
					self:_log("error", `Data ilegível em {key}, backup em Meta.CorruptBackup`)
				end
				data = o.deepCopy(o.template)
				data.CreatedAt = now
				isNew = true
			end

			local prepared = self:_prepare(data)
			if not prepared then
				outcome = ProfileCore.Reasons.FutureVersion
				return nil
			end

			rec.Data = prepared
			rec.Meta.SessionLock = { JobId = o.jobId, LockedAt = now }
			return rec
		end)

		if not ok then
			return nil, ProfileCore.Reasons.Error
		end
		if outcome == ProfileCore.Reasons.FutureVersion then
			self:_log("warn", `{key} tem versão mais nova que este servidor`)
			return nil, outcome
		end
		if outcome == nil and type(record) == "table" then
			return {
				Key = key,
				Data = record.Data,
				Meta = record.Meta,
				IsNew = isNew,
				LockLost = false,
				Released = false,
			},
				nil
		end
		-- Travado por outro servidor: espera e tenta de novo
		if attempt < o.maxAttempts then
			o.wait(o.retryBaseDelay * 2 ^ (attempt - 1))
		end
	end
	return nil, ProfileCore.Reasons.Locked
end

--[[
	Salva o perfil. Com release = true, libera a trava (jogador saindo).
	Se outro servidor assumiu a trava, NÃO grava (o save dele é o válido) e marca LockLost.
]]
function ProfileCore:save(profile: Profile, release: boolean?): (boolean, string?)
	local o: Options = self.o
	if profile.LockLost then
		return false, ProfileCore.Reasons.LockLost
	end
	if profile.Released then
		return false, ProfileCore.Reasons.Released
	end

	local lost = false
	local now: number = o.now()
	profile.Data.LastSave = now
	-- Cópia para gravar: o jogo pode continuar mexendo em profile.Data durante o save
	local snapshot = o.deepCopy(profile.Data)

	local ok = self:_update(profile.Key, function(old: any): any
		lost = false
		local rec: { [string]: any } = if type(old) == "table" then old else { Meta = {} }
		if type(rec.Meta) ~= "table" then
			rec.Meta = {}
		end
		local lock = rec.Meta.SessionLock
		if type(lock) == "table" and lock.JobId ~= o.jobId then
			lost = true
			return nil
		end
		rec.Data = snapshot
		rec.Meta.SavedAt = now
		rec.Meta.SessionLock = if release then nil else { JobId = o.jobId, LockedAt = now }
		return rec
	end)

	if not ok then
		return false, ProfileCore.Reasons.Error
	end
	if lost then
		profile.LockLost = true
		self:_log("warn", `{profile.Key}: outro servidor assumiu a trava, save cancelado`)
		return false, ProfileCore.Reasons.LockLost
	end
	if release then
		profile.Released = true
	end
	return true, nil
end

return ProfileCore
