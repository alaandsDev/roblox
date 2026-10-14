--[[
	Pack de auras SINTÉTICO para o teste do auditor (tests/auras_audit_test.py).
	    lune run tests/roblox/SyntheticAurasPack.luau build/auras_audit_test/pack.rbxm
	Imita a estrutura de um pack da Creator Store: auras por pasta com VFX, scripts (inclusive
	com padrões suspeitos, como TEXTO — nada aqui é executado), remotes, bindables, body mover,
	som, Humanoid/Animator (o Animator é marcado com tag para existir o chunk "Tags").
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance
local Vector3 = roblox.Vector3

local out = process.args[1] or "build/auras_audit_test/pack.rbxm"
local pack = Instance.new("Model")
pack.Name = "Auras Pack"

local function aura(name: string, emitters: number, texture: string, extra: ((Instance, BasePart) -> ())?)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = pack
	local part = Instance.new("Part")
	part.Name = "Handle"
	part.Parent = folder
	for i = 1, emitters do
		local a = Instance.new("Attachment")
		a.Name = "Att" .. i
		a.Position = Vector3.new(0, i, 0)
		a.Parent = part
		local e = Instance.new("ParticleEmitter")
		e.Name = "Emitter" .. i
		e.Texture = texture
		e.Rate = 20 * i
		e.Parent = a
	end
	if extra then
		extra(folder, part)
	end
	return folder
end

aura("Electric Aura", 3, "rbxassetid://1111111", function(folder, part)
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = part, part
	local beam = Instance.new("Beam")
	beam.Name = "Lightning"
	beam.Texture = "rbxassetid://2222222"
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Parent = part
	local light = Instance.new("PointLight")
	light.Parent = part
	local s = Instance.new("Script")
	s.Name = "AuraHandler"
	s.Source = "local m = require(123456789)\nlocal r = game.ReplicatedStorage.AuraRemote\nr.OnServerEvent:Connect(function() end)"
	s.Parent = folder
end)
aura("Fire Aura", 2, "rbxassetid://3333333", function(folder, part)
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = part, part
	local trail = Instance.new("Trail")
	trail.Texture = "rbxassetid://4444444"
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Parent = part
	local snd = Instance.new("Sound")
	snd.SoundId = "rbxassetid://5555555"
	snd.Parent = part
	local ls = Instance.new("LocalScript")
	ls.Name = "Spin"
	ls.Source = "local p = game.Players.LocalPlayer\nlocal c = p.Character\nloadstring('x')"
	ls.Disabled = true
	ls.Parent = folder
	local bv = Instance.new("BodyVelocity")
	bv.Parent = part
end)
aura("Void Ring", 2, "rbxasset://textures/particles/smoke_main.dds")

local remote = Instance.new("RemoteEvent")
remote.Name = "AuraRemote"
remote.Parent = pack
local bindable = Instance.new("BindableEvent")
bindable.Name = "AuraChanged"
bindable.Parent = pack
local dummy = Instance.new("Model")
dummy.Name = "Dummy"
dummy.Parent = pack
local hum = Instance.new("Humanoid")
hum.Parent = dummy
local animator = Instance.new("Animator")
animator.Parent = hum
animator:AddTag("AuraAnimator")
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://6666666"
anim.Parent = dummy
local mod = Instance.new("ModuleScript")
mod.Name = "Config"
mod.Source = "return {}"
mod.Parent = pack

fs.writeDir(string.match(out, "^(.*)/[^/]*$") or ".")
fs.writeFile(out, roblox.serializeModel({ pack }))
print("pack sintético de auras: " .. out)
