--!strict
-- Formatação de números para a interface. Módulo puro (testável fora do Roblox).

local NumberFormatter = {}

-- Sufixos de 10^3 em 10^3. Depois de "Dc" (10^33) usamos notação científica.
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function isBad(n: number): boolean
	return n ~= n or n == math.huge or n == -math.huge
end

-- Trunca (não arredonda para cima): 1999 com 1 casa vira "1.9K", nunca "2.0K".
local function truncate(n: number, decimals: number): number
	local factor = 10 ^ decimals
	return math.floor(n * factor + 1e-9) / factor
end

local function trimZeros(text: string): string
	if string.find(text, "%.") then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text
end

-- 1234 -> "1.23K", 1500000 -> "1.5M", 999 -> "999", -2500 -> "-2.5K"
function NumberFormatter.abbreviate(n: number, decimals: number?): string
	if isBad(n) then
		return "∞"
	end
	local places = decimals or 2
	local negative = n < 0
	local absolute = math.abs(n)
	-- Índice do sufixo pelo expoente (dividir por 1000 várias vezes acumula erro:
	-- 1e33 virava "1000No" em vez de "1Dc")
	local exponent = if absolute >= 1 then math.floor(math.log10(absolute) / 3 + 1e-9) else 0
	local index = exponent + 1
	local value = absolute / 10 ^ (exponent * 3)
	local text: string
	if index > #SUFFIXES then
		text = string.format("%.2e", absolute)
	elseif index == 1 then
		text = trimZeros(string.format(`%.{places}f`, truncate(value, places)))
	else
		text = trimZeros(string.format(`%.{places}f`, truncate(value, places))) .. SUFFIXES[index]
	end
	return if negative then "-" .. text else text
end

-- 1234567 -> "1.234.567" (separador de milhar no padrão pt-BR)
function NumberFormatter.thousands(n: number, separator: string?): string
	if isBad(n) then
		return "∞"
	end
	local sep = separator or "."
	local negative = n < 0
	local digits = tostring(math.floor(math.abs(n)))
	local result = string.reverse((string.gsub(string.reverse(digits), "(%d%d%d)", "%1" .. sep)))
	if string.sub(result, 1, #sep) == sep then
		result = string.sub(result, #sep + 1)
	end
	return if negative then "-" .. result else result
end

function NumberFormatter.money(n: number): string
	return "$" .. NumberFormatter.abbreviate(n)
end

-- 3725 -> "1:02:05", 65 -> "01:05"
function NumberFormatter.duration(seconds: number): string
	local total = math.max(0, math.floor(if isBad(seconds) then 0 else seconds))
	local h = total // 3600
	local m = (total % 3600) // 60
	local s = total % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%02d:%02d", m, s)
end

return NumberFormatter
