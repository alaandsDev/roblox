--!strict
--[[
	CameraShake: tremida de câmera reutilizável (ruído suave que decai).
	    local shake = CameraShake.new()
	    shake:Add(0.6, 0.5)              -- intensidade, duração (s)
	    camera.CFrame = base * shake:Sample()
	Não mexe em nenhuma câmera sozinho: quem usa aplica o Sample() no CFrame que controla
	(a cinemática usa a câmera do próprio ViewportFrame, a câmera do jogador nunca fica presa).
	Respeita a configuração "Tremer câmera" (enabled = false -> Sample() = identidade).
]]

local CameraShake = {}
CameraShake.__index = CameraShake

type Impulse = { intensity: number, duration: number, started: number }

function CameraShake.new(enabled: boolean?): any
	return setmetatable({ impulses = {} :: { Impulse }, enabled = enabled ~= false, seed = math.random() * 100 }, CameraShake)
end

function CameraShake:Add(intensity: number, duration: number)
	if not self.enabled or intensity <= 0 then
		return
	end
	table.insert(self.impulses, { intensity = intensity, duration = duration, started = os.clock() })
end

-- Intensidade atual (0 = parado)
function CameraShake:Amount(): number
	local now = os.clock()
	local total = 0
	for i = #self.impulses, 1, -1 do
		local impulse = self.impulses[i]
		local t = (now - impulse.started) / impulse.duration
		if t >= 1 then
			table.remove(self.impulses, i)
		else
			total += impulse.intensity * (1 - t) ^ 2
		end
	end
	return total
end

function CameraShake:Sample(): CFrame
	local amount = self:Amount()
	if amount <= 0 then
		return CFrame.identity
	end
	local t = os.clock() * 22
	local s = self.seed
	local x = math.noise(t, s, 0) * amount
	local y = math.noise(s, t, 1) * amount
	local r = math.noise(s, 2, t) * amount
	return CFrame.new(x * 1.2, y * 1.2, 0) * CFrame.Angles(0, 0, math.rad(r * 4))
end

function CameraShake:Clear()
	table.clear(self.impulses)
end

return CameraShake
