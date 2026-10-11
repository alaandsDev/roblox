--!strict
--[[
	MusicController (Fase 11): música de fundo opcional (Configurações > Música de fundo).
	Usa ReplicatedStorage.Assets.Sounds.Music (TODO_ASSET: licença a conferir, ver ASSETS.md),
	em loop e volume baixo. Desligada por padrão.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local AssetLoader = require(ReplicatedStorage.Shared.Modules.AssetLoader)
local DataController = require(script.Parent.DataController)

local MusicController = {}

local VOLUME = 0.2
local music: Sound? = nil

local function apply()
	local settings = DataController.Get("Settings") or {}
	if settings.Music then
		if not music then
			local asset = AssetLoader.clone("Sounds", "Music")
			if asset and asset:IsA("Sound") then
				asset.Looped = true
				asset.Volume = VOLUME
				asset.Parent = SoundService
				music = asset
			end
		end
		if music and not music.IsPlaying then
			music:Play()
		end
	elseif music then
		music:Stop()
	end
end

function MusicController.Start()
	DataController.Wait()
	apply()
	DataController.Changed:Connect(function(key)
		if key == "Settings" then
			apply()
		end
	end)
end

return MusicController
