local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RestaurantUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end
local function stroke(parent, transparency)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(90, 104, 128)
	s.Transparency = transparency or .3
	s.Thickness = 1
	s.Parent = parent
	return s
end
local function label(parent, text, size, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = font or Enum.Font.Gotham
	l.TextColor3 = color or Color3.fromRGB(235, 239, 246)
	l.TextSize = size or 14
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local orderCard = Instance.new("Frame")
orderCard.Name = "OrderCard"
orderCard.Position = UDim2.fromOffset(18, 18)
orderCard.Size = UDim2.fromOffset(350, 178)
orderCard.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
orderCard.BackgroundTransparency = .06
orderCard.BorderSizePixel = 0
orderCard.Parent = gui
corner(orderCard, 16)
stroke(orderCard, .18)

local orderAccent = Instance.new("Frame")
orderAccent.Size = UDim2.fromOffset(5, 142)
orderAccent.Position = UDim2.fromOffset(0, 18)
orderAccent.BackgroundColor3 = Color3.fromRGB(255, 190, 75)
orderAccent.BorderSizePixel = 0
orderAccent.Parent = orderCard
corner(orderAccent, 3)

local orderTitle = label(orderCard, "CURRENT ORDER", 13, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 92))
orderTitle.Position = UDim2.fromOffset(20, 12)
orderTitle.Size = UDim2.new(1, -40, 0, 20)
orderTitle.TextXAlignment = Enum.TextXAlignment.Left

local orderName = label(orderCard, "No active order", 22, Enum.Font.GothamBold, Color3.fromRGB(250, 252, 255))
orderName.Position = UDim2.fromOffset(20, 34)
orderName.Size = UDim2.new(1, -40, 0, 30)
orderName.TextXAlignment = Enum.TextXAlignment.Left

local orderStatus = label(orderCard, "Walk to the first customer and press E", 13, Enum.Font.GothamSemibold, Color3.fromRGB(181, 193, 211))
orderStatus.Position = UDim2.fromOffset(20, 66)
orderStatus.Size = UDim2.new(1, -40, 0, 36)
orderStatus.TextXAlignment = Enum.TextXAlignment.Left

local progressBack = Instance.new("Frame")
progressBack.Position = UDim2.fromOffset(20, 108)
progressBack.Size = UDim2.new(1, -40, 0, 9)
progressBack.BackgroundColor3 = Color3.fromRGB(45, 51, 63)
progressBack.BorderSizePixel = 0
progressBack.Parent = orderCard
corner(progressBack, 9)
local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = Color3.fromRGB(255, 190, 75)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBack
corner(progressFill, 9)

local timerText = label(orderCard, "READY", 12, Enum.Font.GothamBold, Color3.fromRGB(146, 157, 177))
timerText.Position = UDim2.fromOffset(20, 123)
timerText.Size = UDim2.new(.5, -20, 0, 20)
timerText.TextXAlignment = Enum.TextXAlignment.Left
local stepText = label(orderCard, "Step 0/0", 12, Enum.Font.GothamBold, Color3.fromRGB(146, 157, 177))
stepText.Position = UDim2.new(.5, 0, 123, 0)
stepText.Size = UDim2.new(.5, -20, 0, 20)
stepText.TextXAlignment = Enum.TextXAlignment.Right

local hint = label(orderCard, "Customer → Kitchen → Serving Counter", 11, Enum.Font.Gotham, Color3.fromRGB(111, 124, 145))
hint.Position = UDim2.fromOffset(20, 146)
hint.Size = UDim2.new(1, -40, 0, 18)
hint.TextXAlignment = Enum.TextXAlignment.Left

local money = Instance.new("Frame")
money.Name = "CashDisplay"
money.AnchorPoint = Vector2.new(1, 0)
money.Position = UDim2.new(1, -18, 0, 18)
money.Size = UDim2.fromOffset(178, 58)
money.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
money.BackgroundTransparency = .06
money.BorderSizePixel = 0
money.Parent = gui
corner(money, 16)
stroke(money, .18)
local moneyLabel = label(money, "$0", 24, Enum.Font.GothamBold, Color3.fromRGB(102, 226, 139))
moneyLabel.Size = UDim2.fromScale(1, 1)
moneyLabel.TextXAlignment = Enum.TextXAlignment.Center

local levelCard = Instance.new("Frame")
levelCard.Name = "LevelCard"
levelCard.AnchorPoint = Vector2.new(1, 0)
levelCard.Position = UDim2.new(1, -18, 0, 88)
levelCard.Size = UDim2.fromOffset(260, 92)
levelCard.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
levelCard.BackgroundTransparency = .06
levelCard.BorderSizePixel = 0
levelCard.Parent = gui
corner(levelCard, 16)
stroke(levelCard, .18)
local levelLabel = label(levelCard, "RESTAURANT LEVEL 1", 15, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 92))
levelLabel.Position = UDim2.fromOffset(15, 9)
levelLabel.Size = UDim2.new(1, -30, 0, 22)
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
local xpLabel = label(levelCard, "0 / 100 XP", 11, Enum.Font.Gotham, Color3.fromRGB(166, 178, 197))
xpLabel.Position = UDim2.fromOffset(15, 31)
xpLabel.Size = UDim2.new(1, -30, 0, 17)
xpLabel.TextXAlignment = Enum.TextXAlignment.Left
local xpBack = Instance.new("Frame")
xpBack.Position = UDim2.fromOffset(15, 58)
xpBack.Size = UDim2.new(1, -30, 0, 10)
xpBack.BackgroundColor3 = Color3.fromRGB(45, 51, 63)
xpBack.BorderSizePixel = 0
xpBack.Parent = levelCard
corner(xpBack, 10)
local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = Color3.fromRGB(89, 171, 255)
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBack
corner(xpFill, 10)

local inventoryCard = Instance.new("Frame")
inventoryCard.Name = "InventoryCard"
inventoryCard.AnchorPoint = Vector2.new(0, 1)
inventoryCard.Position = UDim2.new(0, 18, 1, -18)
inventoryCard.Size = UDim2.fromOffset(350, 62)
inventoryCard.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
inventoryCard.BackgroundTransparency = .08
inventoryCard.BorderSizePixel = 0
inventoryCard.Parent = gui
corner(inventoryCard, 15)
stroke(inventoryCard, .22)
local inventoryTitle = label(inventoryCard, "PANTRY", 11, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 92))
inventoryTitle.Position = UDim2.fromOffset(13, 8)
inventoryTitle.Size = UDim2.fromOffset(55, 18)
inventoryTitle.TextXAlignment = Enum.TextXAlignment.Left
local inventoryText = label(inventoryCard, "Rice 8  •  Pasta 8  •  Beans 8  •  Falafel 8", 11, Enum.Font.Gotham, Color3.fromRGB(180, 191, 207))
inventoryText.Position = UDim2.fromOffset(13, 29)
inventoryText.Size = UDim2.new(1, -26, 0, 20)
inventoryText.TextXAlignment = Enum.TextXAlignment.Left

local toast = Instance.new("Frame")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(.5, 0)
toast.Position = UDim2.new(.5, 0, 0, -90)
toast.Size = UDim2.fromOffset(430, 64)
toast.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
toast.BackgroundTransparency = .04
toast.BorderSizePixel = 0
toast.Visible = false
toast.Parent = gui
corner(toast, 16)
stroke(toast, .18)
local toastTitle = label(toast, "", 13, Enum.Font.GothamBold, Color3.fromRGB(255, 205, 92))
toastTitle.Position = UDim2.fromOffset(16, 8)
toastTitle.Size = UDim2.new(1, -32, 0, 19)
toastTitle.TextXAlignment = Enum.TextXAlignment.Left
local toastBody = label(toast, "", 12, Enum.Font.GothamSemibold, Color3.fromRGB(205, 213, 225))
toastBody.Position = UDim2.fromOffset(16, 28)
toastBody.Size = UDim2.new(1, -32, 0, 27)
toastBody.TextXAlignment = Enum.TextXAlignment.Left

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash")
local level = leaderstats:WaitForChild("Level")
local xp = leaderstats:WaitForChild("XP")
local remotes = ReplicatedStorage:WaitForChild("RestaurantRemotes")
local statusEvent = remotes:WaitForChild("OrderStatus")
local stateEvent = remotes:WaitForChild("OrderState")

local thresholds = {0,100,250,450,700,1000,1400,1850,2400,3000}
local function updateCash() moneyLabel.Text = string.format("$%d", cash.Value) end
local function updateLevel()
	levelLabel.Text = string.format("RESTAURANT LEVEL %d", level.Value)
	local current=xp.Value; local currentThreshold=thresholds[level.Value] or 0; local nextThreshold=thresholds[level.Value+1]
	if nextThreshold then xpLabel.Text=string.format("%d / %d XP",current,nextThreshold); xpFill.Size=UDim2.fromScale(math.clamp((current-currentThreshold)/(nextThreshold-currentThreshold),0,1),1) else xpLabel.Text=string.format("%d XP • MAX TIER",current); xpFill.Size=UDim2.fromScale(1,1) end
end
cash.Changed:Connect(updateCash); level.Changed:Connect(updateLevel); xp.Changed:Connect(updateLevel); updateCash(); updateLevel()

local toastId=0
local function showToast(titleText,bodyText)
	toastId+=1; local id=toastId; toastTitle.Text=titleText; toastBody.Text=bodyText; toast.Visible=true; toast.Position=UDim2.new(.5,0,0,-90)
	TweenService:Create(toast,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,0,18)}):Play()
	task.delay(3.2,function() if id~=toastId then return end; local tween=TweenService:Create(toast,TweenInfo.new(.25,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.new(.5,0,0,-90)}); tween:Play(); tween.Completed:Wait(); if id==toastId then toast.Visible=false end end)
end

statusEvent.OnClientEvent:Connect(function(titleText,message)
	orderName.Text=titleText
	orderStatus.Text=message
	showToast(titleText,message)
end)

stateEvent.OnClientEvent:Connect(function(state)
	if not state then return end
	orderName.Text=state.order or "No active order"
	orderStatus.Text=state.status or "Ready"
	local total=state.total or 0
	local step=state.step or 0
	local remaining=state.remaining or 0
	stepText.Text=total>0 and string.format("Step %d/%d",math.min(step,total),total) or "Step 0/0"
	timerText.Text=remaining>0 and string.format("⏱ %ds",remaining) or "READY"
	if total>0 then progressFill.Size=UDim2.fromScale(math.clamp((step-1)/total,0,1),1) else progressFill.Size=UDim2.fromScale(0,1) end
	if remaining<=10 and remaining>0 then orderAccent.BackgroundColor3=Color3.fromRGB(255,92,92) else orderAccent.BackgroundColor3=Color3.fromRGB(255,190,75) end
	local inv=state.inventory or {}
	inventoryText.Text=string.format("Rice %d  •  Pasta %d  •  Beans %d  •  Falafel %d",inv.Rice or 0,inv.Pasta or 0,(inv.FavaBeans or 0),(inv.FalafelMix or 0))
end)
print("RestaurantUI: polished order, timer, XP, pantry and notification HUD ready")
