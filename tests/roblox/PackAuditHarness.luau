--[[
	Testa tools/packaudit/PackAudit com um pack SINTÉTICO montado aqui (nenhum asset real):
	R15 com arma/VFX/script perigoso, R6 simples com roupas, rig custom estático.
	Também confere que um .rbxm salvo e lido de volta é auditado sem executar scripts.
]]
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Env = require("./Env")
local PackAudit = require("../../tools/packaudit/PackAudit")

local Instance = roblox.Instance
local T = Env.checker("Auditoria de pack de personagens (sintético)")
local check = T.check

local function part(className, name, parent)
	local p = Instance.new(className)
	p.Name = name
	p.Parent = parent
	return p
end

local pack = Instance.new("Folder")
pack.Name = "Anime Pack"
local naruto = part("Folder", "NARUTO", pack)
local other = part("Folder", "OTHER", pack)
local dbz = part("Folder", "DBZ", pack)

-- 1) R15 "Ninja" com katana, cabelo, VFX, animação e um script backdoor
local ninja = part("Model", "Ninja", naruto)
part("Humanoid", "Humanoid", ninja)
part("Part", "HumanoidRootPart", ninja)
for _, name in { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "LeftHand", "RightFoot" } do
	local mp = part("MeshPart", name, ninja)
	pcall(function()
		mp.MeshId = "rbxassetid://" .. tostring(1000 + #name)
		mp.TextureID = "rbxassetid://" .. tostring(2000 + #name)
	end)
end
part("Motor6D", "Neck", ninja.UpperTorso)
local hair = part("Accessory", "SpikyHair", ninja)
part("MeshPart", "Handle", hair)
local katana = part("Model", "KatanaBlade", ninja)
part("Part", "Blade", katana)
part("ParticleEmitter", "Aura", ninja.UpperTorso)
part("Trail", "SwordTrail", katana.Blade)
local anim = part("Animation", "Idle", ninja)
pcall(function()
	anim.AnimationId = "rbxassetid://555"
end)
local backdoor = part("Script", "Animate", ninja)
backdoor.Source = "local m = require(123456789)\nm.go()\n"
local fx = part("LocalScript", "SpinFX", ninja)
fx.Source = "local TweenService = game:GetService('TweenService')\n-- rotate\n"

-- 2) R6 simples com roupas e rosto
local guy = part("Model", "Student", other)
part("Humanoid", "Humanoid", guy)
part("Part", "HumanoidRootPart", guy)
local head = part("Part", "Head", guy)
local face = part("Decal", "face", head)
pcall(function()
	face.Texture = "rbxassetid://777"
end)
for _, name in { "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" } do
	part("Part", name, guy)
end
local shirt = part("Shirt", "Shirt", guy)
pcall(function()
	shirt.ShirtTemplate = "rbxassetid://888"
end)
part("Pants", "Pants", guy)

-- 3) Estátua custom sem HumanoidRootPart e sem Motor6D
local statue = part("Model", "Statue", pack)
part("AnimationController", "AnimationController", statue)
part("Part", "Body", statue)

-- Script solto fora de personagem
-- Formas do mesmo personagem (DBZ): Goku, Goku SSJ, Goku (Ultra Instinct) + Vegeta
for _, name in { "Goku", "Goku SSJ", "Goku (Ultra Instinct)", "Vegeta" } do
	local m = part("Model", name, dbz)
	part("Humanoid", "Humanoid", m)
	part("Part", "HumanoidRootPart", m)
end

local loose = part("ModuleScript", "Loader", pack)
loose.Source = "return loadstring(game:HttpGet('x'))"

-- Ida e volta por .rbxm (como o arquivo exportado do Studio)
local bytes = roblox.serializeModel({ pack })
local roots = roblox.deserializeModel(bytes)
local report = PackAudit.audit(roots)

local byName = {}
for _, c in report.characters do
	byName[c.name] = c
end
check(#report.characters == 7, "acha os 7 personagens dentro das pastas (Model com Humanoid/AnimationController)")
check(byName.Ninja.category == "NARUTO" and byName.Student.category == "OTHER" and byName.Goku.category == "DBZ" and byName.Statue.category == "(raiz)", "categoria = pasta do pack (DBZ, NARUTO...)")
local gokuForms = nil
for _, group in report.forms do
	if group.base == "goku" then
		gokuForms = group
	end
end
check(gokuForms ~= nil and #gokuForms.members == 3 and table.find(gokuForms.members, "Vegeta") == nil, "formas: Goku / Goku SSJ / Goku (Ultra Instinct) agrupados; Vegeta fora")
check(PackAudit.baseName("Naruto Sage Mode") == "naruto" and PackAudit.baseName("Ichigo (Bankai)") == "ichigo", "nome base remove palavras de forma")
local summary = PackAudit.summary(report)
check(#summary.characters == 7 and summary.categories.DBZ == 4, "resumo JSON por personagem/categoria")
local dump = PackAudit.scriptDump(roots)
check(string.find(dump, "require(123456789)", 1, true) ~= nil and string.find(dump, "risco ALTO", 1, true) ~= nil, "código dos scripts exportado como TEXTO para revisão")
check(byName.Ninja and byName.Ninja.rig == "R15", "Ninja = R15")
check(byName.Student and byName.Student.rig == "R6", "Student = R6")
check(byName.Statue and string.sub(byName.Statue.rig, 1, 6) == "custom", "Statue = rig custom")
check(#byName.Ninja.hair == 1 and #byName.Ninja.vfx >= 2 and #byName.Ninja.animations == 1, "cabelo, VFX e animação do Ninja")
local hasKatana = false
for _, w in byName.Ninja.weapons do
	if string.find(w, "Katana", 1, true) then
		hasKatana = true
	end
end
check(hasKatana, "arma detectada pelo nome (KatanaBlade)")
check(byName.Student.shirt == "888" and byName.Student.face == "777", "roupa e rosto do Student")
check(#report.scripts == 3, "lista TODOS os scripts (3, incluindo o solto)")
local risks = {}
for _, s in report.scripts do
	risks[s.name] = s.risk
end
check(risks.Animate == "ALTO", "require(id numérico) = risco ALTO mesmo com nome inocente 'Animate'")
check(risks.Loader == "ALTO", "loadstring/HttpGet = risco ALTO")
check(risks.SpinFX == "BAIXO", "TweenService decorativo = risco BAIXO")
check(byName.Ninja.compatibility == "ALTA depois de remover scripts", "Ninja: compatível depois de remover scripts")
local statueProblem = false
for _, p in byName.Statue.problems do
	if string.find(p, "HumanoidRootPart", 1, true) then
		statueProblem = true
	end
end
check(statueProblem and string.find(byName.Statue.compatibility, "MÉDIA", 1, true) == 1, "Statue: problemas apontados (sem HumanoidRootPart)")
check(byName.Ninja.score > byName.Student.score and byName.Student.score > byName.Statue.score, "nota de qualidade ordena Ninja > Student > Statue")
check(byName.Ninja.suggestedRarity == "Secret", "melhor nota recebe a sugestão mais rara")
local md = PackAudit.markdown(report, "Anime Pack", "14679137059", "teste.rbxm")
check(string.find(md, "## 1. Segurança", 1, true) ~= nil and string.find(md, "### 1. Ninja", 1, true) ~= nil, "relatório markdown gerado")
-- Nenhum script do pack rodou (o backdoor chamaria require e quebraria/alteraria algo)
check(#Env.errors == 0, "nada foi executado durante a auditoria")

local failures = T.finish()
process.exit(if failures > 0 then 1 else 0)
