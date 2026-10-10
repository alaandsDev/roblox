local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local function formatNumber(n: number): string
	local index = 1
	while n >= 1000 and index < #SUFFIXES do
		n /= 1000
		index += 1
	end
	if index == 1 then
		return tostring(math.floor(n))
	end
	return string.format("%.1f%s", n, SUFFIXES[index])
end

local function get(key: string): number
	return player:GetAttribute(key) or Config.StartingData[key]
end

local gui = Instance.new("ScreenGui")
gui.Name = "SimulatorGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0, 0.5)
frame.Position = UDim2.new(0, 16, 0.5, 0)
frame.Size = UDim2.fromOffset(240, 0)
frame.AutomaticSize = Enum.AutomaticSize.Y
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BackgroundTransparency = 0.2
frame.Parent = gui

Instance.new("UICorner").Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = frame

local order = 0
local function make(className: string, color: Color3?): TextLabel
	order += 1
	local obj = Instance.new(className)
	obj.LayoutOrder = order
	obj.Size = UDim2.new(1, 0, 0, 32)
	obj.Font = Enum.Font.GothamBold
	obj.TextSize = 16
	obj.TextColor3 = Color3.new(1, 1, 1)
	if color then
		obj.BackgroundColor3 = color
		Instance.new("UICorner").Parent = obj
	else
		obj.BackgroundTransparency = 1
		obj.TextXAlignment = Enum.TextXAlignment.Left
	end
	obj.Parent = frame
	return obj
end

local energiaLabel = make("TextLabel")
local moedasLabel = make("TextLabel")
local rebirthsLabel = make("TextLabel")
local clickButton = make("TextButton", Color3.fromRGB(60, 140, 255))
local sellButton = make("TextButton", Color3.fromRGB(70, 180, 90))

local upgradeButtons = {}
for upgradeId in Config.Upgrades do
	local button = make("TextButton", Color3.fromRGB(150, 90, 220))
	button.Activated:Connect(function()
		remotes.BuyUpgrade:FireServer(upgradeId)
	end)
	upgradeButtons[upgradeId] = button
end

local rebirthButton = make("TextButton", Color3.fromRGB(230, 120, 40))

clickButton.Activated:Connect(function()
	remotes.Click:FireServer()
end)
sellButton.Activated:Connect(function()
	remotes.Sell:FireServer()
end)
rebirthButton.Activated:Connect(function()
	remotes.Rebirth:FireServer()
end)

local function refresh()
	local rebirths = get("Rebirths")
	energiaLabel.Text = `⚡ Energia: {formatNumber(get("Energia"))} / {formatNumber(get("Capacidade"))}`
	moedasLabel.Text = `💰 Moedas: {formatNumber(get("Moedas"))}`
	rebirthsLabel.Text = `🔁 Rebirths: {rebirths} (x{Config.multiplier(rebirths)})`
	clickButton.Text = `Clicar (+{formatNumber(Config.clickGain(get("ClickPower"), rebirths))})`
	sellButton.Text = "Vender energia"
	for upgradeId, button in upgradeButtons do
		local upgrade = Config.Upgrades[upgradeId]
		button.Text = `{upgrade.Nome} +{upgrade.Incremento} ({formatNumber(Config.upgradeCost(upgradeId, get(upgradeId)))} 💰)`
	end
	rebirthButton.Text = `Rebirth ({formatNumber(Config.rebirthCost(rebirths))} 💰)`
end

player.AttributeChanged:Connect(refresh)
refresh()

gui.Parent = player:WaitForChild("PlayerGui")
