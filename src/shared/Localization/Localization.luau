--!strict
-- Tradução dos textos da interface.
--   Localization.t("welcome", { game = "Roll Legends" }) -> "Bem-vindo ao Roll Legends!"
-- Se a chave não existir no idioma atual, usa pt-BR; se nem lá existir, mostra a própria chave
-- (assim um texto esquecido aparece na tela e é fácil de achar).

local Localization = {}

type Dictionary = { [string]: string }

local dictionaries: { [string]: Dictionary }? = nil
local currentLocale = "pt-BR"
local FALLBACK = "pt-BR"

local function load(): { [string]: Dictionary }
	if not dictionaries then
		-- Carregamento tardio: o módulo também funciona fora do Roblox nos testes,
		-- onde os dicionários são definidos com setDictionaries.
		dictionaries = {
			["pt-BR"] = require(script.Parent.PtBR) :: any,
			["en-US"] = require(script.Parent.EnUS) :: any,
		}
	end
	return dictionaries :: { [string]: Dictionary }
end

-- Troca {nome} pelos valores de params
function Localization.format(template: string, params: { [string]: any }?): string
	if not params then
		return template
	end
	return (string.gsub(template, "{([%w_]+)}", function(name)
		local value = (params :: any)[name]
		return if value ~= nil then tostring(value) else "{" .. name .. "}"
	end))
end

function Localization.t(key: string, params: { [string]: any }?): string
	local all = load()
	local text = (all[currentLocale] and all[currentLocale][key]) or (all[FALLBACK] and all[FALLBACK][key])
	return Localization.format(text or key, params)
end

function Localization.setLocale(locale: string)
	currentLocale = locale
end

function Localization.getLocale(): string
	return currentLocale
end

-- Para testes
function Localization.setDictionaries(dicts: { [string]: Dictionary })
	dictionaries = dicts
end

return Localization
