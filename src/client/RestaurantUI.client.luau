local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "RestaurantUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local orderFrame = Instance.new("Frame")
orderFrame.Name = "OrderCard"
orderFrame.Position = UDim2.fromOffset(24, 24)
orderFrame.Size = UDim2.fromOffset(330, 142)
orderFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
orderFrame.BackgroundTransparency = 0.08
orderFrame.BorderSizePixel = 0
orderFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = orderFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 85, 105)
stroke.Transparency = 0.25
stroke.Parent = orderFrame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 11)
title.Size = UDim2.new(1, -36, 0, 24)
title.Font = Enum.Font.GothamBold
title.Text = "CURRENT ORDER"
title.TextColor3 = Color3.fromRGB(255, 205, 80)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = orderFrame

local orderText = Instance.new("TextLabel")
orderText.BackgroundTransparency = 1
orderText.Position = UDim2.fromOffset(18, 38)
orderText.Size = UDim2.new(1, -36, 0, 27)
orderText.Font = Enum.Font.GothamBold
orderText.Text = "No active order"
orderText.TextColor3 = Color3.fromRGB(245, 247, 250)
orderText.TextSize = 20
orderText.TextXAlignment = Enum.TextXAlignment.Left
orderText.Parent = orderFrame

local statusText = Instance.new("TextLabel")
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.fromOffset(18, 68)
statusText.Size = UDim2.new(1, -36, 0, 42)
statusText.Font = Enum.Font.GothamSemibold
statusText.Text = "Customer is waiting — go take the order"
statusText.TextColor3 = Color3.fromRGB(185, 195, 210)
statusText.TextSize = 14
statusText.TextWrapped = true
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = orderFrame

local hintText = Instance.new("TextLabel")
hintText.BackgroundTransparency = 1
hintText.Position = UDim2.fromOffset(18, 113)
hintText.Size = UDim2.new(1, -36, 0, 20)
hintText.Font = Enum.Font.Gotham
hintText.Text = "Order Counter → Cooking → Delivery"
hintText.TextColor3 = Color3.fromRGB(120, 135, 155)
hintText.TextSize = 11
hintText.TextXAlignment = Enum.TextXAlignment.Left
hintText.Parent = orderFrame

local cashFrame = Instance.new("Frame")
cashFrame.Name = "CashDisplay"
cashFrame.AnchorPoint = Vector2.new(1, 0)
cashFrame.Position = UDim2.new(1, -24, 0, 24)
cashFrame.Size = UDim2.fromOffset(170, 54)
cashFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
cashFrame.BackgroundTransparency = 0.08
cashFrame.BorderSizePixel = 0
cashFrame.Parent = gui

local cashCorner = Instance.new("UICorner")
cashCorner.CornerRadius = UDim.new(0, 14)
cashCorner.Parent = cashFrame

local cashLabel = Instance.new("TextLabel")
cashLabel.BackgroundTransparency = 1
cashLabel.Size = UDim2.fromScale(1, 1)
cashLabel.Font = Enum.Font.GothamBold
cashLabel.Text = "$0"
cashLabel.TextColor3 = Color3.fromRGB(95, 220, 130)
cashLabel.TextSize = 22
cashLabel.Parent = cashFrame

local progressFrame = Instance.new("Frame")
progressFrame.Name = "ProgressDisplay"
progressFrame.AnchorPoint = Vector2.new(1, 0)
progressFrame.Position = UDim2.new(1, -24, 0, 88)
progressFrame.Size = UDim2.fromOffset(250, 82)
progressFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
progressFrame.BackgroundTransparency = 0.08
progressFrame.BorderSizePixel = 0
progressFrame.Parent = gui

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 14)
progressCorner.Parent = progressFrame

local levelLabel = Instance.new("TextLabel")
levelLabel.BackgroundTransparency = 1
levelLabel.Position = UDim2.fromOffset(14, 8)
levelLabel.Size = UDim2.new(1, -28, 0, 22)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextColor3 = Color3.fromRGB(255, 205, 80)
levelLabel.TextSize = 16
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = progressFrame

local xpLabel = Instance.new("TextLabel")
xpLabel.BackgroundTransparency = 1
xpLabel.Position = UDim2.fromOffset(14, 31)
xpLabel.Size = UDim2.new(1, -28, 0, 18)
xpLabel.Font = Enum.Font.Gotham
xpLabel.TextColor3 = Color3.fromRGB(185, 195, 210)
xpLabel.TextSize = 12
xpLabel.TextXAlignment = Enum.TextXAlignment.Left
xpLabel.Parent = progressFrame

local xpBar = Instance.new("Frame")
xpBar.Position = UDim2.fromOffset(14, 56)
xpBar.Size = UDim2.new(1, -28, 0, 10)
xpBar.BackgroundColor3 = Color3.fromRGB(50, 56, 70)
xpBar.BorderSizePixel = 0
xpBar.Parent = progressFrame

local xpBarCorner = Instance.new("UICorner")
xpBarCorner.CornerRadius = UDim.new(1, 0)
xpBarCorner.Parent = xpBar

local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = Color3.fromRGB(95, 175, 255)
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBar

local xpFillCorner = Instance.new("UICorner")
xpFillCorner.CornerRadius = UDim.new(1, 0)
xpFillCorner.Parent = xpFill

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local level = leaderstats:WaitForChild("Level")
local xp = leaderstats:WaitForChild("XP")

local function updateCash()
	cashLabel.Text = string.format("$%d", cash.Value)
end

local function updateProgress()
	levelLabel.Text = string.format("RESTAURANT LEVEL %d", level.Value)
	local currentXP = xp.Value
	local thresholds = {0, 100, 250, 450, 700, 1000, 1400, 1850, 2400, 3000}
	local currentThreshold = thresholds[level.Value] or 0
	local nextThreshold = thresholds[level.Value + 1]
	if nextThreshold then
		xpLabel.Text = string.format("%d / %d XP", currentXP, nextThreshold)
		local range = nextThreshold - currentThreshold
		xpFill.Size = UDim2.fromScale(math.clamp((currentXP - currentThreshold) / range, 0, 1), 1)
	else
		xpLabel.Text = string.format("%d XP • MAX TIER", currentXP)
		xpFill.Size = UDim2.fromScale(1, 1)
	end
end

cash:GetPropertyChangedSignal("Value"):Connect(updateCash)
level:GetPropertyChangedSignal("Value"):Connect(updateProgress)
xp:GetPropertyChangedSignal("Value"):Connect(updateProgress)
updateCash()
updateProgress()

local remotes = ReplicatedStorage:WaitForChild("RestaurantRemotes")
local orderStatusEvent = remotes:WaitForChild("OrderStatus")

orderStatusEvent.OnClientEvent:Connect(function(orderName: string, status: string)
	orderText.Text = orderName
	statusText.Text = status
end)
