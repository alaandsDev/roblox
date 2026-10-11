--!strict
--[[
	InventoryService: unidades do jogador, estações da base e nível individual.
	    InventoryService.Add(player, characterId, variant?) -> uid
	    InventoryService.Remove(player, { uid })
	    InventoryService.IsFull(player) / Capacity(player) / Count(player)
	    InventoryService.UnlockedSlots(player) -> { [slotId] = true }
	    InventoryService.UpgradeCharacter(player, uid, quantidade) -> resultado (ou Net.fail)
	    InventoryService.EquipChanged   -> Signal(player)        (estações mudaram)
	    InventoryService.ItemChanged    -> Signal(player, uid)   (nível/flags de uma unidade)

	Toda validação acontece aqui (servidor): dono do uid, slot liberado pela progressão,
	slot livre, proteção, dinheiro. O cliente só pede.
	O inventário é mandado ao cliente aos pedaços (evento InventoryDelta), nunca inteiro a cada roll.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local CharacterLevelConfig = require(Shared.Config.CharacterLevelConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)

local InventoryCore = require(script.Parent.Parent.Core.InventoryCore)
local PlayerDataService = require(script.Parent.PlayerDataService)
local MapService = require(script.Parent.MapService)
local EconomyService = require(script.Parent.EconomyService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local InventoryService = {}

InventoryService.EquipChanged = Signal.new()
InventoryService.ItemChanged = Signal.new()
-- (player, uid, nivelNovo, niveisSubidos)
InventoryService.CharacterUpgraded = Signal.new()

local function dataOf(player: Player): any
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	return data
end

-- Envia só o que mudou no inventário
function InventoryService.SendDelta(player: Player, set: { string }?, removed: { string }?)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end
	local payload = { set = {}, removed = removed or {} }
	for _, uid in (set or {}) :: { string } do
		local item = data.Inventory[uid]
		if item then
			payload.set[uid] = TableUtil.deepCopy(item)
		end
	end
	Net.fire("InventoryDelta", player, payload)
end

local function equipChanged(player: Player)
	local data = PlayerDataService.GetData(player)
	if data then
		PlayerDataService.Set(player, "EquippedCharacters", TableUtil.deepCopy(data.EquippedCharacters))
	end
	InventoryService.EquipChanged:Fire(player)
end

function InventoryService.Count(player: Player): number
	local data = PlayerDataService.GetData(player)
	return if data then InventoryCore.count(data) else 0
end

function InventoryService.Capacity(player: Player): number
	local data = PlayerDataService.GetData(player)
	return if data then Formulas:capacity(data) else 0
end

function InventoryService.IsFull(player: Player): boolean
	return InventoryService.Count(player) >= InventoryService.Capacity(player)
end

function InventoryService.UnlockedSlots(player: Player): { [number]: boolean }
	local data = PlayerDataService.GetData(player)
	local state = MapService.Progression:state(if data then data.Rebirths or 0 else 0)
	return state.unlockedSlots
end

function InventoryService.Add(player: Player, characterId: string, variant: string?): string
	local data = PlayerDataService.GetData(player)
	assert(data, "dados não carregados")
	assert(CharacterConfig.ById[characterId], "personagem inválido")
	local uid = InventoryCore.add(data, characterId, os.time(), variant)
	PlayerDataService.Replicate(player, "NextUid")
	InventoryService.SendDelta(player, { uid }, nil)
	return uid
end

function InventoryService.Remove(player: Player, uids: { string })
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end
	local wasEquipped = false
	local removed = {}
	for _, uid in uids do
		if InventoryCore.slotOf(data, uid) then
			wasEquipped = true
		end
		if InventoryCore.remove(data, uid) then
			table.insert(removed, uid)
		end
	end
	InventoryService.SendDelta(player, nil, removed)
	if wasEquipped then
		equipChanged(player)
	end
end

------------------------------------------------------------------------------------
-- Equipar

function InventoryService.Equip(player: Player, uid: string, slotId: number?): number
	local data = dataOf(player)
	local ok, err, slot = InventoryCore.equip(data, uid, slotId, InventoryService.UnlockedSlots(player))
	if not ok then
		Net.fail(err :: string)
	end
	equipChanged(player)
	AnalyticsService.Track(player, "CharacterEquipped", { id = data.Inventory[uid].Id, slot = slot })
	return slot :: number
end

function InventoryService.Unequip(player: Player, uid: string)
	local data = dataOf(player)
	local ok, err = InventoryCore.unequip(data, uid)
	if not ok then
		Net.fail(err :: string)
	end
	equipChanged(player)
	return true
end

function InventoryService.EquipBest(player: Player): number
	local data = dataOf(player)
	local placed = InventoryCore.equipBest(data, InventoryService.UnlockedSlots(player), CharacterConfig.ById)
	equipChanged(player)
	return placed
end

-- Quando a progressão muda (Rebirth), remove de slots que deixaram de valer
function InventoryService.Revalidate(player: Player)
	local data = PlayerDataService.GetData(player)
	if data then
		InventoryCore.dropInvalidSlots(data, InventoryService.UnlockedSlots(player))
		equipChanged(player)
	end
end

------------------------------------------------------------------------------------
-- Nível individual (estação)

export type UpgradeResult = { uid: string, level: number, levels: number, cost: number, income: number, nextCost: number? }

--[[
	1. encontra o personagem  2. valida dono  3. valida equipado (CharacterLevelConfig.RequireEquipped)
	4. calcula custo  5. confere Money  6. desconta  7. sobe o Level  8. recalcula renda
	9. avisa a base (ItemChanged -> estação)  10. devolve o resultado
	Tudo sem yield: dois pedidos simultâneos não sobem o mesmo nível duas vezes.
]]
function InventoryService.UpgradeCharacter(player: Player, uid: string, count: number?): UpgradeResult
	local data = dataOf(player)
	local item = data.Inventory[uid]
	if not item then
		Net.fail("not_owned")
	end
	if CharacterLevelConfig.RequireEquipped and not InventoryCore.slotOf(data, uid) then
		Net.fail("not_equipped")
	end
	local level = item.Level or 1
	if level >= CharacterLevelConfig.MaxLevel then
		Net.fail("max_level")
	end
	local wanted = math.clamp(math.floor(count or 1), 1, CharacterLevelConfig.MaxBatch)
	local cost, levels = Formulas:characterUpgradeCost(item.Id, level, wanted)
	if levels <= 0 then
		Net.fail("max_level")
	end
	if not EconomyService.TrySpend(player, cost) then
		Net.fail("not_enough_money")
	end
	item.Level = level + levels
	InventoryService.SendDelta(player, { uid }, nil)
	InventoryService.ItemChanged:Fire(player, uid)
	InventoryService.CharacterUpgraded:Fire(player, uid, item.Level, levels)
	Net.fire("StationUpgraded", player, uid, item.Level)
	AnalyticsService.Track(player, "CharacterUpgraded", { id = item.Id, level = item.Level })
	local nextCost, nextLevels = Formulas:characterUpgradeCost(item.Id, item.Level, 1)
	return {
		uid = uid,
		level = item.Level,
		levels = levels,
		cost = cost,
		income = Formulas:stationIncome(data, item),
		nextCost = if nextLevels > 0 then nextCost else nil,
	}
end

------------------------------------------------------------------------------------

function InventoryService.Init()
	Net.handle("EquipCharacter", function(player, uid, slotId)
		return InventoryService.Equip(player, uid, slotId)
	end)
	Net.handle("UnequipCharacter", function(player, uid)
		return InventoryService.Unequip(player, uid)
	end)
	Net.handle("EquipBest", function(player)
		return InventoryService.EquipBest(player)
	end)
	Net.handle("SetCharacterFlag", function(player, uid, flag, value)
		local data = dataOf(player)
		local ok, err = InventoryCore.setFlag(data, uid, flag, value)
		if not ok then
			Net.fail(err :: string)
		end
		InventoryService.SendDelta(player, { uid }, nil)
		InventoryService.ItemChanged:Fire(player, uid)
		return value
	end)
	Net.handle("UpgradeCharacter", function(player, uid, count)
		return InventoryService.UpgradeCharacter(player, uid, count)
	end)
end

function InventoryService.Start()
	-- Perfis antigos/progressão: limpa slots inválidos ao carregar
	local function onLoaded(player: Player)
		local data = PlayerDataService.GetData(player)
		if data then
			InventoryCore.dropInvalidSlots(data, InventoryService.UnlockedSlots(player))
		end
	end
	PlayerDataService.Loaded:Connect(onLoaded)
	for _, player in Players:GetPlayers() do
		if PlayerDataService.IsLoaded(player) then
			onLoaded(player)
		end
	end
end

return InventoryService
