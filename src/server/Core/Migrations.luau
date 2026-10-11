--!strict
-- Migrações do formato dos dados do Roll Legends (para FUTURAS atualizações).
-- Módulo puro: testado fora do Roblox.
--
-- Migrations[N] recebe dados da versão N-1 e devolve dados na versão N.
-- Exemplo (quando SchemaVersion virar 2):
--   Migrations[2] = function(data)
--       data.Gems = data.Gems or 0
--       data.Settings.Music = true
--       return data
--   end
-- O ProfileCore aplica todas em sequência até DataConfig.SchemaVersion e depois
-- completa o que faltar com o Template.
-- NUNCA apague uma migração antiga: jogadores que ficaram meses fora ainda precisam dela.

local Migrations: { [number]: (data: { [string]: any }) -> { [string]: any } } = {}

return Migrations
