--!strict
-- Mini framework de testes (roda com o binário "luau", fora do Roblox).

local TestLib = {}

local results = { passed = 0, failed = 0, failures = {} :: { string } }
local currentSuite = ""

local function show(value: any): string
	if type(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for k, v in a do
		if not deepEqual(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

function TestLib.describe(name: string, fn: () -> ())
	currentSuite = name
	fn()
end

function TestLib.it(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		results.passed += 1
	else
		results.failed += 1
		table.insert(results.failures, `{currentSuite} > {name}\n      {tostring(err)}`)
	end
end

function TestLib.expect(actual: any)
	local api = {}
	function api.toBe(expected: any)
		if actual ~= expected then
			error(`esperado {show(expected)}, veio {show(actual)}`, 2)
		end
	end
	function api.toEqual(expected: any)
		if not deepEqual(actual, expected) then
			error("tabelas diferentes", 2)
		end
	end
	function api.toBeTruthy()
		if not actual then
			error(`esperado verdadeiro, veio {show(actual)}`, 2)
		end
	end
	function api.toBeFalsy()
		if actual then
			error(`esperado falso, veio {show(actual)}`, 2)
		end
	end
	function api.toBeNil()
		if actual ~= nil then
			error(`esperado nil, veio {show(actual)}`, 2)
		end
	end
	return api
end

function TestLib.report(): boolean
	print("")
	for _, failure in results.failures do
		print("  ✗ " .. failure)
	end
	print(`\n{results.passed} passaram, {results.failed} falharam`)
	return results.failed == 0
end

return TestLib
