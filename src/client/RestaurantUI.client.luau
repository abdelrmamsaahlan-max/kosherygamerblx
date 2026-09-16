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
orderFrame.Size = UDim2.fromOffset(300, 112)
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
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -36, 0, 26)
title.Font = Enum.Font.GothamBold
title.Text = "CURRENT ORDER"
title.TextColor3 = Color3.fromRGB(255, 205, 80)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = orderFrame

local orderText = Instance.new("TextLabel")
orderText.BackgroundTransparency = 1
orderText.Position = UDim2.fromOffset(18, 40)
orderText.Size = UDim2.new(1, -36, 0, 24)
orderText.Font = Enum.Font.GothamSemibold
orderText.Text = "No active order"
orderText.TextColor3 = Color3.fromRGB(245, 247, 250)
orderText.TextSize = 19
orderText.TextXAlignment = Enum.TextXAlignment.Left
orderText.Parent = orderFrame

local statusText = Instance.new("TextLabel")
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.fromOffset(18, 70)
statusText.Size = UDim2.new(1, -36, 0, 24)
statusText.Font = Enum.Font.Gotham
statusText.Text = "Go to the Order Counter"
statusText.TextColor3 = Color3.fromRGB(170, 180, 195)
statusText.TextSize = 13
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = orderFrame

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

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")

local function updateCash()
	cashLabel.Text = string.format("$%d", cash.Value)
end

cash:GetPropertyChangedSignal("Value"):Connect(updateCash)
updateCash()

local remotes = ReplicatedStorage:WaitForChild("RestaurantRemotes")
local orderStatusEvent = remotes:WaitForChild("OrderStatus")

orderStatusEvent.OnClientEvent:Connect(function(orderName: string, status: string)
	orderText.Text = orderName
	statusText.Text = status
end)
